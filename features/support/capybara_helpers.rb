module CapybaraHelpers
  def confirm_modal_if_present
    if Capybara.current_driver == Capybara.javascript_driver
      accept_confirm { yield }
      return
    end

    yield
  end
end
