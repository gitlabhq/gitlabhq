module CountryCodes
  extend self

  def for_select
    @countries ||= I18n.t(:countries)
                       .map { |code, label| [label, code] }
                       .sort_by { |label_with_code| label_with_code[0] }
  end
end
