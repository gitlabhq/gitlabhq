module BootstrapFormBuilderCustomization
  def label_class
    "label-bold"
  end
end

BootstrapForm::FormBuilder.prepend(BootstrapFormBuilderCustomization)
