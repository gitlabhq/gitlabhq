module EE
  module IssuablesHelper
    def weight_dropdown_label(weight)
      if Issue.weight_options.include?(weight)
        weight
      else
        h(weight.presence || 'Weight')
      end
    end
  end
end
