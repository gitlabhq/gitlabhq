module ChronicDurationAttribute
  extend ActiveSupport::Concern

  class_methods do
    def chronic_duration_attr(virtual_attribute, source_attribute)
      chronic_duration_attr_reader(virtual_attribute, source_attribute)
      chronic_duration_attr_writer(virtual_attribute, source_attribute)
    end

    def chronic_duration_attr_reader(virtual_attribute, source_attribute)
      define_method(virtual_attribute) do
        value = self.send(source_attribute) # rubocop:disable GitlabSecurity/PublicSend

        return '' if value.nil?

        ChronicDuration.output(value, format: :short)
      end
    end

    def chronic_duration_attr_writer(virtual_attribute, source_attribute)
      define_method("#{virtual_attribute}=") do |value|
        new_value = ChronicDuration.parse(value).to_i
        new_value = nil if new_value <= 0

        self.send("#{source_attribute}=", new_value) # rubocop:disable GitlabSecurity/PublicSend

        new_value
      end
    end
  end
end
