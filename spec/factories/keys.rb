require_relative '../support/helpers/key_generator_helper'

FactoryBot.define do
  factory :key do
    title
    key { Spec::Support::Helpers::KeyGeneratorHelper.new(1024).generate + ' dummy@gitlab.com' }

    factory :deploy_key, class: 'DeployKey'

    factory :personal_key do
      user
    end

    factory :another_key do
      factory :another_deploy_key, class: 'DeployKey'
    end

    factory :rsa_key_2048 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFf6RYK3qu/RKF/3ndJmL5xgMLp3O9
          6x8lTay+QGZ0+9FnnAXMdUqBq/ZU6d/gyMB4IaW3nHzM1w049++yAB6UPCzMB8Uo27K5
          /jyZCtj7Vm9PFNjF/8am1kp46c/SeYicQgQaSBdzIW3UDEa1Ef68qroOlvpi9PYZ/tA7
          M0YP0K5PXX+E36zaIRnJVMPT3f2k+GnrxtjafZrwFdpOP/Fol5BQLBgcsyiU+LM1SuaC
          rzd8c9vyaTA1CxrkxaZh+buAi0PmdDtaDrHd42gqZkXCKavyvgM5o2CkQ5LJHCgzpXy0
          5qNFzmThBSkb+XtoxbyagBiGbVZtSVow6Xa7qewz= dummy@gitlab.com
        KEY
      end

      factory :rsa_deploy_key_2048, class: 'DeployKey'
    end

    factory :dsa_key_2048 do
      key do
        <<~KEY.delete("\n")
          ssh-dss AAAAB3NzaC1kc3MAAAEBAO/3/NPLA/zSFkMOCaTtGo+uos1flfQ5f038Uk+G
          Y9AeLGzX+Srhw59GdVXmOQLYBrOt5HdGwqYcmLnE2VurUGmhtfeO5H+3p5pGJbkS0Gxp
          YH1HRO9lWsncF3Hh1w4lYsDjkclDiSTdfTuN8F4Kb3DXNnVSCieeonp+B25F/CXagyTQ
          /pvNmHFeYgGCVdnBtFdi+xfxaZ8NKdPrGggzokbKHElDZQ4Xo5EpdcyLajgM7nB2r2Rz
          OrmeaevKi5lV68ehRa9Yyrb7vxvwiwBwOgqR/mnN7Gnaq1jUdmJY+ct04Qwx37f5jvhv
          5gA4U40SGMoiHM8RFIN7Ksz0jsyX73MAAAAVALRWOfjfzHpK7KLz4iqDvvTUAevJAAAB
          AEa9NZ+6y9iQ5erGsdfLTXFrhSefTG0NhghoO/5IFkSGfd8V7kzTvCHaFrcfpEA5kP8t
          poeOG0TASB6tgGOxm1Bq4Wncry5RORBPJlAVpDGRcvZ931ddH7IgltEInS6za2uH6F/1
          M1QfKePSLr6xJ1ZLYfP0Og5KTp1x6yMQvfwV0a+XdA+EPgaJWLWp/pWwKWa0oLUgjsIH
          MYzuOGh5c708uZrmkzqvgtW2NgXhcIroRgynT3IfI2lP2rqqb3uuuE/qH5UCUFO+Dc3H
          nAFNeQDT/M25AERdPYBAY5a+iPjIgO+jT7BfmfByT+AZTqZySrCyc7nNZL3YgGLK0l6A
          1GgAAAEBAN9FpFOdIXE+YEZhKl1vPmbcn+b1y5zOl6N4x1B7Q8pD/pLMziWROIS8uLzb
          aZ0sMIWezHIkxuo1iROMeT+jtCubn7ragaN6AX7nMpxYUH9+mYZZs/fyElt6wCviVhTI
          zM+u7VdQsnZttOOlQfogHdL+SpeAft0DsfJjlcgQnsLlHQKv6aPqCPYUST2nE7RyW/Ex
          PrMxLtOWt0/j8RYHbwwqvyeZqBz3ESBgrS9c5tBdBfauwYUV/E7gPLOU3OZFw9ue7o+z
          wzoTZqW6Xouy5wtWvSLQSLT5XwOslmQz8QMBxD0AQyDfEFGsBCWzmbTgKv9uqrBjubsS
          Taja+Cf9kMo== dummy@gitlab.com
        KEY
      end
    end

    factory :ecdsa_key_256 do
      key do
        <<~KEY.delete("\n")
          ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYA
          AABBBJZmkzTgY0fiCQ+DVReyH/fFwTFz0XoR3RUO0u+199H19KFw7mNPxRSMOVS7tEtO
          Nj3Q7FcZXfqthHvgAzDiHsc= dummy@gitlab.com
        KEY
      end
    end

    factory :ed25519_key_256 do
      key do
        <<~KEY.delete("\n")
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIETnVTgzqC1gatgSlC4zH6aYt2CAQzgJ
          OhDRvf59ohL6 dummy@gitlab.com
        KEY
      end
    end
  end
end
