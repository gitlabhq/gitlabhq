module ChronicDurationAttribute
  extend ActiveSupport::Concern

  class_methods do
    def chronic_duration_attribute(virtual_attribute, source_attribute)
      chronic_duration_attribute_reader(virtual_attribute, source_attribute)
      chronic_duration_attribute_writer(virtual_attribute, source_attribute)
    end

    def chronic_duration_attribute_reader(virtual_attribute, source_attribute)
      define_method(virtual_attribute) do
        value = self.send(source_attribute) # rubocop:disable GitlabSecurity/PublicSend
        ChronicDuration.output(value, format: :short) unless value.nil?
      end
    end

    def chronic_duration_attribute_writer(virtual_attribute, source_attribute)
      define_method("#{virtual_attribute}=") do |value|
        new_value = ChronicDuration.parse(value).to_i
        self.send("#{source_attribute}=", new_value) # rubocop:disable GitlabSecurity/PublicSend
        new_value
      end
    end
  end
end
