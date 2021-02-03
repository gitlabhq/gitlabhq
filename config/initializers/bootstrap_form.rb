# frozen_string_literal: true

module BootstrapFormBuilderCustomization
  def label_class
    "label-bold"
  end
end

BootstrapForm::FormBuilder.prepend(BootstrapFormBuilderCustomization)
