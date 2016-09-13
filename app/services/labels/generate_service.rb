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
        { title: 'bug', color: red },
        { title: 'critical', color: red },
        { title: 'confirmed', color: red },
        { title: 'documentation', color: yellow },
        { title: 'support', color: yellow },
        { title: 'discussion', color: blue },
        { title: 'suggestion', color: blue },
        { title: 'enhancement', color: green }
      ]
    end
  end
end
