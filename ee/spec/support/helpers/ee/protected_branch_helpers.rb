module EE
  module ProtectedBranchHelpers
    def set_allowed_to(operation, option = 'Masters', form: '.js-new-protected-branch')
      within form do
        find(".js-allowed-to-#{operation}").click
        wait_for_requests

        within('.dropdown-content') do
          Array(option).each { |opt| click_on(opt) }
        end

        find(".js-allowed-to-#{operation}").click # needed to submit form in some cases
      end
    end
  end
end
