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
      virtual_attribute_validator = "#{virtual_attribute}_validator".to_sym
      validation_error = "#{virtual_attribute}_error".to_sym

      validate virtual_attribute_validator
      attr_accessor validation_error

      define_method("#{virtual_attribute}=") do |value|
        begin
          self.send("#{validation_error}=", '') # rubocop:disable GitlabSecurity/PublicSend

          new_value =
            if value.blank?
              nil
            else
              ChronicDuration.parse(value).to_i
            end

          self.send("#{source_attribute}=", new_value) # rubocop:disable GitlabSecurity/PublicSend
        rescue ChronicDuration::DurationParseError => ex
          self.send("#{validation_error}=", ex.message) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      define_method(virtual_attribute_validator) do
        error = self.send(validation_error) # rubocop:disable GitlabSecurity/PublicSend
        self.send('errors').add(source_attribute, error) unless error.blank? # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
