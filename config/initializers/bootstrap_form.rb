module BootstrapFormBuilderCustomization
  def label_class
    "label-light"
  end
end

BootstrapForm::FormBuilder.prepend(BootstrapFormBuilderCustomization)
