module QA
  module Page
    module Project
      module Repository
        module Branch
          class New < Page::Base
            def choose_ref(ref)
              fill_in 'ref', with: ref
            end

            def choose_name(branch_name)
              fill_in 'branch_name', with: branch_name
            end

            def create_branch
              click_on 'Create branch'
            end
          end
        end
      end
    end
  end
end
