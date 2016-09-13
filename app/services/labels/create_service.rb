module Labels
  class CreateService < Labels::BaseService
    def execute
      label = subject.labels.build(params)

      return label if subject.is_a?(Project) && subject.group.present? && subject.group.labels.where(title: title).exists?

      if label.save
        if subject.is_a?(Group)
          subject.projects.each do |project|
            project.labels.find_or_create_by!(title: title) do |label|
              label.color = color
              label.description = description
            end
          end
        end
      end

      label
    end

    private

    def title
      params[:title]
    end

    def color
      params[:color]
    end

    def description
      params[:description]
    end
  end
end
