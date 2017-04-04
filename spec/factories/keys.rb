FactoryGirl.define do
  factory :key do
    title
    key do
      'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= dummy@gitlab.com'
    end

    factory :deploy_key, class: 'DeployKey' do
      key do
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFf6RYK3qu/RKF/3ndJmL5xgMLp3O96x8lTay+QGZ0+9FnnAXMdUqBq/ZU6d/gyMB4IaW3nHzM1w049++yAB6UPCzMB8Uo27K5/jyZCtj7Vm9PFNjF/8am1kp46c/SeYicQgQaSBdzIW3UDEa1Ef68qroOlvpi9PYZ/tA7M0YP0K5PXX+E36zaIRnJVMPT3f2k+GnrxtjafZrwFdpOP/Fol5BQLBgcsyiU+LM1SuaCrzd8c9vyaTA1CxrkxaZh+buAi0PmdDtaDrHd42gqZkXCKavyvgM5o2CkQ5LJHCgzpXy05qNFzmThBSkb+XtoxbyagBiGbVZtSVow6Xa7qewz'
      end
    end

    factory :personal_key do
      user
    end

    factory :another_key do
      key do
        'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmTillFzNTrrGgwaCKaSj+QCz81E6jBc/s9av0+3b1Hwfxgkqjl4nAK/OD2NjgyrONDTDfR8cRN4eAAy6nY8GLkOyYBDyuc5nTMqs5z3yVuTwf3koGm/YQQCmo91psZ2BgDFTor8SVEE5Mm1D1k3JDMhDFxzzrOtRYFPci9lskTJaBjpqWZ4E9rDTD2q/QZntCqbC3wE9uSemRQB5f8kik7vD/AD8VQXuzKladrZKkzkONCPWsXDspUitjM8HkQdOf0PsYn1CMUC1xKYbCxkg5TkEosIwGv6CoEArUrdu/4+10LVslq494mAvEItywzrluCLCnwELfW+h/m8UHoVhZ'
      end

      factory :another_deploy_key, class: 'DeployKey' do
      end
    end
  end
end
