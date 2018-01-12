module QA
  module Runtime
    module User
      extend self

      def name
        ENV['GITLAB_USERNAME'] || 'root'
      end

      def password
        ENV['GITLAB_PASSWORD'] || '5iveL!fe'
      end

      def ssh_key
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFf6RYK3qu/RKF/3ndJmL5xgMLp3O9
          6x8lTay+QGZ0+9FnnAXMdUqBq/ZU6d/gyMB4IaW3nHzM1w049++yAB6UPCzMB8Uo27K5
          /jyZCtj7Vm9PFNjF/8am1kp46c/SeYicQgQaSBdzIW3UDEa1Ef68qroOlvpi9PYZ/tA7
          M0YP0K5PXX+E36zaIRnJVMPT3f2k+GnrxtjafZrwFdpOP/Fol5BQLBgcsyiU+LM1SuaC
          rzd8c9vyaTA1CxrkxaZh+buAi0PmdDtaDrHd42gqZkXCKavyvgM5o2CkQ5LJHCgzpXy0
          5qNFzmThBSkb+XtoxbyagBiGbVZtSVow6Xa7qewz= dummy@gitlab.com
        KEY
      end
    end
  end
end
