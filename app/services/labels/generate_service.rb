module Labels
  class GenerateService < Labels::BaseService
    def execute
      label_params.each do |params|
        Labels::CreateService.new(subject, user, params).execute
      end
    end

    private

    def label_params
      red = '#d9534f'
      yellow = '#f0ad4e'
      blue = '#428bca'
      green = '#5cb85c'

      [
        { title: 'bug', color: red, label_type: params[:label_type] },
        { title: 'critical', color: red, label_type: params[:label_type] },
        { title: 'confirmed', color: red, label_type: params[:label_type] },
        { title: 'documentation', color: yellow, label_type: params[:label_type] },
        { title: 'support', color: yellow, label_type: params[:label_type] },
        { title: 'discussion', color: blue, label_type: params[:label_type] },
        { title: 'suggestion', color: blue, label_type: params[:label_type] },
        { title: 'enhancement', color: green, label_type: params[:label_type] }
      ]
    end
  end
end
