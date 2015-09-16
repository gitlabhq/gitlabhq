module Ci
  module IconsHelper
    def boolean_to_icon(value)
      if value.to_s == "true"
        content_tag :i, nil, class: 'fa fa-circle cgreen'
      else
        content_tag :i, nil, class: 'fa fa-power-off clgray'
      end
    end
  end
end
