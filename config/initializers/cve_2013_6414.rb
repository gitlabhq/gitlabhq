# Monkey patch for Ruby on Rails vulnerability CVE-2013-6414
# https://groups.google.com/d/msg/ruby-security-ann/A-ebV4WxzKg/KNPTbX8XAQUJ

ActiveSupport.on_load(:action_view) do
  ActionView::LookupContext::DetailsKey.class_eval do
    class << self
      alias :old_get :get

      def get(details)
        if details[:formats]
          details = details.dup
          syms    = Set.new Mime::SET.symbols
          details[:formats] = details[:formats].select { |v|
            syms.include? v
          }
        end
        old_get details
      end
    end
  end
end
