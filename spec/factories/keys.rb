# frozen_string_literal: true

FactoryBot.define do
  factory :key do
    sequence(:title) { |n| "title #{n}" }
    key do
      # Larger keys take longer to generate, and since this factory gets called frequently,
      # let's only create the smallest one we need.
      SSHData::PrivateKey::RSA.generate(
        ::Gitlab::SSHPublicKey.supported_sizes(:rsa).min, unsafe_allow_small_key: true
      ).public_key.openssh(comment: 'dummy@gitlab.com')
    end
    trait :expired do
      to_create { |key| key.save!(validate: false) }
      expires_at { 2.days.ago }
    end

    trait :expired_today do
      to_create { |key| key.save!(validate: false) }
      expires_at { Date.current.beginning_of_day + 3.hours }
    end

    trait :without_md5_fingerprint do
      after(:create) do |key|
        key.update_column(:fingerprint, nil)
      end
    end

    factory :key_without_comment do
      key { SSHData::PrivateKey::RSA.generate(3072, unsafe_allow_small_key: true).public_key.openssh }
    end

    factory :deploy_key, class: 'DeployKey' do
      transient do
        # rubocop:disable Lint/EmptyBlock -- block is required by factorybot
        readonly_access_to {}
        write_access_to {}
        # rubocop:enable Lint/EmptyBlock
      end

      after(:build) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(true) }

      after(:create) do |deploy_key, evaluator|
        Gitlab::ExclusiveLease.set_skip_transaction_check_flag(nil)
        Array.wrap(evaluator.readonly_access_to).each do |project|
          create(:deploy_keys_project, :readonly_access, deploy_key: deploy_key, project: project)
        end
        Array.wrap(evaluator.write_access_to).each do |project|
          create(:deploy_keys_project, :write_access, deploy_key: deploy_key, project: project)
        end
      end

      trait :owned do
        user
      end

      trait :private do
        public { false }
      end

      trait :public do
        public { true }
      end
    end

    factory :personal_key do
      user
    end

    factory :personal_key_4096 do
      user

      key { SSHData::PrivateKey::RSA.generate(4096, unsafe_allow_small_key: true).public_key.openssh(comment: 'dummy@gitlab.com') }
    end

    factory :another_key do
      after(:build) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(true) }
      after(:create) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(nil) }

      factory :another_deploy_key, class: 'DeployKey'
    end

    factory :rsa_key_1024 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDAPd3PCZexjKqeQVjhwPsnZ1tD23BP1
          53gg0VE9iM/V3KsuRze3HZkMGZLiKPVRJis9W31TPXor+aZfHn+OrbfW3h/W0XSopPxPs
          guAcnHMA8LSMFxkXSJk9Is9NBPN4etV6oSMEUcHc2P3UKWXs575OJ/MToF/N9nICT35y0
          NXw== dummy@gitlab.com
        KEY
      end
    end

    factory :rsa_key_2048 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC98dbu7gxcbmAvwMqz/6AALhSr1jiX
          G0UC8FQMvoDt+ciB+uSJhg7KlxinKjYJnPGfhX+q2K+mmCGAmI/D6q7rFxE+bn09O+75
          qgkTHi+suDVE6KG7L3n0alGd/qSevfomR77Snh6fQPdG6sEAZz3kehcpfVnq5/IuLFq9
          FBrgmu52Jd4XZLQZKkDq6zYOJ69FUkGf93LZIV/OOaS+f+qkOGPCUkdKl7oEcgpVNY9S
          RjBCduXnvi2CyQnnJVkBguGL5VlXwFXH+17Whs7oFWmdiG+4jzBRLIMz4EuIW09b8Su5
          PW6+bBuXOifHA8KG5TMmjs5LYdCMPFnhTyDyO3a1 dummy@gitlab.com
        KEY
      end

      factory :rsa_deploy_key_2048, class: 'DeployKey' do
        after(:build) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(true) }
        after(:create) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(nil) }
      end
    end

    factory :rsa_key_4096 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGSD77lLtjmzewiBs6nu2R5nu6oNkrA
          kH/0co1fHHosKfRr+sWkSTKXOVcL7bhRu+tniGBmB5pn+i1qX7BXtrcnv//bCXWIp+me0
          27L4RJa5/Ep077iiTJlzTpcV664xNUXC8mzBr601HR/Z2TzX5DWJvnyqqFkN7qHTYo/+I
          oKECnKqNzI5SQrAxgi6sbWA5DFQ/nwcqsUSBo5gCCJ/0QPrR19yVV5lJA19EY2LawOb1S
          JNOFo4mQupSlBZwvERZJ7IqhBTPtQIfrqqz5VJbI13jK3ViZTugIZqydWAhosUyejP3Sd
          Cj1KMexrvV95tjUtmhVFlph4tKThQO0p9pXKZNCzYsbQTye6O6Hk2rojOJLyFWqNBVKtI
          8Ymfu7OQWppRnuUFuhuuS515H1s888bZFMPsC74mPyo0Y7Q9wAoTnQ9Hw6b0J6OfY3PIR
          VphaCmxh6b7dgSPFdD7TA6j0xk6PCTOIEzBKuc85B3GQc8Nt4sTv6fW8lGeuYWqepW74i
          geC4qB6U3/3+p3nPdq/bTM1txrhnQsl1r4dv6TLZ51EtHp6sXayp0qd0pRaiavebXFC0i
          aETLraQpye4FWbBL/8xTjQ/0VPrYVuUCDvDSMIIS3/9g7Kp7ERUDC9jUqOVonm4pTXL9i
          ItiUBlK7Mob9C4fQIRFnVR00DCmkmVgw== dummy@gitlab.com
        KEY
      end
    end

    factory :rsa_key_5120 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACgQDxnZP0TucLH3zcrvt75DPNq+xKqOmJk
          CEzTytKq4S5MDH0nlx+xOZ9WykhwDHXU0iZBJF7yRdLkZweYDJVKnBzr4t7QP5Sw2/ZdL
          elvUMWGJjuz28x8Z+8NZ+IxL/exDz7itrhCsLupQhGO1obiIwf8xVzzPoxrQ9dxaN4x96
          5N+QdQcld8O6xfpSE0p5Y3sRn3kp57aHWoNa/bUGZy0OHLr/ig0uc6EKyWsTmEESOgDyV
          94wOyHR0KNGEENyxQt4BwAbEBn3Y41HKqD358KKh+XjbECebrrBFigdDL/eYFIUlstJ07
          SK/HtYjZbiUZCPs8bJA+SBaLK0pGGqguM2LXRoMeMUZFwKKKS2LpRqjKGj3Qt7qMnp1Sk
          VhiMnxNqL4nJnDOOVo07xDIPKqIBYO67/cp4Icv3IjKxy6K3EIpLr+iRCxcllpDogxolz
          FC+pEDVpmEvcrGEv1ON6HcCdk/6Q8Iekr8rYDHpKCU5FF2uBHkqq7yNJ1/+NFC4dgyOo0
          xCVL4D3DvDKNxFYkrzW4ICt0f5XcMnU10yS/OFXz8JwA3jvuLvMRe5JdFiIjb/l86+TgY
          yvK8Y8N/UWgSgyjXUCv8nxdvpsxdz5h7HBF8E2DIxCVMC23655e5rp5eJW9EU9X5YFZc3
          u6uWJ1f1aO+1ViTtqkPrqxovNDD+gVel8Ny6MJ4MvmDKY+eM8beNMSSf1n1Oyh/SvCffh
          ZpUqrXdTr9qwZEOaC75T74AJ7KBl9VvO3vPLZuJrt38R2OZG/4SlNEUA6bb5TWQLtdor/
          qpPN5jAskkAUzOh5L/M+dmq2jNn03U9xwORCYPZj+fFM9bL99/0knsV0ypZDZyWH dummy@gitlab.com
        KEY
      end

      factory :rsa_deploy_key_5120, class: 'DeployKey' do
        after(:build) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(true) }
        after(:create) { Gitlab::ExclusiveLease.set_skip_transaction_check_flag(nil) }
      end
    end

    factory :rsa_key_8192 do
      key do
        <<~KEY.delete("\n")
          ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQC5jMyGtgMOVX4t2GuXkbirJA0Edr+ql
          OH9grnRBPHPo0Npt6XE6ZN3J3hDULTQo03wmekGw42dxdNSgk+F0GjsUBrMLbqrk485MM
          e0cUbP4lRXNu4ao87wPVM5fAsD4E3FQiZcI6Df011ZGIL7hGTHt6eafTfr9cJheRyYSu6
          g06rlnFWbbtSh9oQ7Y6sfDLBcsC9ECcXwe3mwViuQXPIVomZ02EdnBbAhbGHDtA+ZbSvT
          fraxOMjkxkVvvdjLxXEykpwVuZf8eZ+R/Js8jQ5RKvTZMbfxJNsGEqHD32s43ml4VF549
          Qz2GJDXF7Cld/n3CT6wvw0mMPM0LnykL2v0CMr44bjIA3KsNEs5MhkcBO8sv5hGfcPhrp
          m9WwI6gd9vdZVcxarVI+iQS947owvdn4VbEZXynCDqEEv3Zh+FA5p23mf2p7DkG/swiK/
          IPrjr1wmsiWmwIUsENzJNyJtibKuRsBawC4ZdL797tFilSoTzSpriegSL13joPXz3eOHC
          Vu4ATHMo3QyLfIFbxrf9PQ79nyOpHoX2YeFXvei3xFkGMundkOqeI+pnJKDyqbiLV7UVl
          clua11QWNQZf1ZUd0n1wZ1g89de+wl3oJSRbSA5ZpveZEPstcMC/JhogY4JBYsvCT1yHO
          oNWHo90NZQsUCjNnR+/FVaACtpt2zcPTjjbXvxwCDlT3gXTmTBp/kEZq6u8p+BOlqFgxc
          P/sdAR8jWTin3Iw/YAcbqNgRHdjMUzJBrPQ5NcK6xFcmkOEQahdJDZs98xozCHkD4Urx6
          +auTr/uqRYobKoNUNiYqN1n7/dfZjQJJVkHtKd06JTFx+7/SqyfrTKS+/EIf2Hypdy9r9
          IFR+SWAOi11N/wflS/ZbH95Qt3STifXRecmHzyYGkMOZ+mg3Hi2YU0yn7k+P1jy627xud
          pT9Ak3HWT5ji8tMyn9udL7m80dYpUiEAxoYZdbSSNCDaKP4ViABnGIeZreIujabI8IdtE
          IjFQTaF2d5HTYjp28/qf576CFP5L7AGydypipYqZUmsYnay5YVjdm89He3TMD71SwspJl
          POC4RnM0HS87OE+U0+mVaIe8YYbcjTekpVU9mkqsE/GQ34Egw79VMNNgWq5avOzpT8msC
          lTJxgfJ1agGgigTvGxUM0FB07+sIdJxxNymAGpLKZ1op8xaJI3o8D86jWgI22za1zxUB5
          il9U7+KOzaWo9mp3bmhvZWGDwzTXEZhUJYMRby7o6UxSHlA6fKE63JSDD2yhXk4CjsQRN
          C7Ph9cYSB+Wa3i9Am4rRlJgrF79okmEOMpj1idliHkpIsy/k2CN9Lf2EIHOD4NMuLrSUH
          4qJsPUq19ZbGIMdImD3vMS5b dummy@gitlab.com
        KEY
      end
    end

    factory :dsa_key_1024 do
      key do
        <<~KEY.delete("\n")
          ssh-dss AAAAB3NzaC1kc3MAAACBAJX6HURfY3e8+ogBskskvAVHohfMG+vjNX1W+Zr2W
          g0gPXmJv6tLy5J81AvTbjypxtPyuLSqdTOgIqFDVgU9+EE9OMTsx2leggPMjfbTSEIK5s
          BjpqiQWLWWL7m73wo5He8uviMGJB7CHyhqHaVwutmU255rh8mC+W9Aa7ZQqgQDAAAAFQD
          IFohzNQANsmFSx7sP/UeVfPihDwAAAIEAkuqRvlCLLHAJbb3logBdRS9xF7vkG7yRnIEw
          lchwDqvUVJ411cJlFVz+9QBdZA4pcKS0L/2nCdZb/Ob0feNkG3cFBH6qqXy5GWZeWnEHL
          GwLvZF5CjqOmwQhp8RUyKNt3yccPyZIcIzvRGxPrP5utGr+hKZ47NGp78yQ4jxvkuUAAA
          CATX5Fl5UsVf8ii74qBjuik18YZFoxlBeIDowU++ArvoGkNKCnRYAGs50aDYQlB+fFpEz
          UBELm0xpIHOwOyhzZ37fVLfLvKijOm6u5mfFZX1URUBmZeELBAFgNp2YiBvWbQwR/jtIp
          zhZs5/p4o1mdfgGxBoM0KU5DHDnI5KrKJqo= dummy@gitlab.com
        KEY
      end
    end

    factory :dsa_key_2048 do
      key do
        <<~KEY.delete("\n")
          ssh-dss AAAAB3NzaC1kc3MAAAEBALEB3sM2kPy6LKLiyL+UlDx2vzuKrzSD2nsW2Kb7
          0ivIqDNJu5CbqIQSkjdMzJiocs33ESFqXid6ezOtVdDwXHJQRxKGalW1kBbFAPjtMxlD
          bf559+7qN2zfCfcQsgTmNAZ7O+wltqJmyLv5i4QqNwPDvyeBvJ4C+770DzlcQtpkflKJ
          X+O7i8Ylq34h6UTCTnjry+dFVm1xz97LPf7XuzXGZcAG/eGUNQgxQ2bferKnrpYOXx6c
          ocSRj9W54nrRFMWuDeOspWp4MoYK0FRMfDQYPksUayGUnm1KQTGuDbB0ahRNCOm8b3tf
          P9Z+vjANAkqenzDuXCpz2PU/Oj6/N/UAAAAhAPOLyut12Mjcp3eUXLe1xSoI5IRXSLso
          W9no93dcFNprAAABAQCLhpqKY+PNcwbhhPruL+f+uROghHzDwRNX+e231F4wHHeDDomf
          WyLVFj31XrHdDXZnS9tTTj5D2XWLovSSxYb3H7earTctmktL0lQ3HapujzvOkn+VM0pG
          s6B3j54+AM3mg50KZdYWxxv+v/lb6oEcsCjfKNyRIx/5pqX6XI3dxl9MMIxrfVWpkNX+
          FI68v1LVV61DC9PkNyEHU0v9YBOfrTiS21TIlVIZcSFhuDjg52MekfZAnoKaP7YFJNF3
          fdCrXaU3hYQrwB9XdskBUppwxKGhf7O6SWEZhAEfPA9kgxaWHoJvsDz8aca576UNe7BP
          mjzo/SLUX+P4uvcaffd+AAABAEqzpmwjzTxB+DV8C+0LnmKf3L/UlQWyGdmhd65rnbkH
          GgRMAAkoh4GBOEHL5bznNRmO7X/H6g2fR7SEabxfbvb903KI4nbfFF+3QtnwyIbTBAcH
          0893D3bi5rsaJcz+c6lBob2En2nThRciefXUk2oPzCQuDyFIyHLJikqRQVcalHCdQ00c
          /H/JkiJedHNqaeU4TeMk8SM53Brjplj/iiJq+ujc5MlEgACdCwWp0BviFACEoYyFaa3R
          kc7Xdm9vFpclm9fzgUfPloASA0SkO945in3mIqMfODTb4yRvbjk8If9483fEPgQkczpd
          ptBz1VAKg8AmRcz1GmBIxs+Stn0= dummy@gitlab.com
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

    factory :ecdsa_sk_key_256 do
      key do
        <<~KEY.delete("\n")
          sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyN
          TZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBDZ+f5tSRhlB7EN39f93SscTN5PUv
          bD3UQsNrlE1ZdbwPMMRul2zlPiUvwAvnJitW0jlD/vwZOW2YN+q+iZ5c0MAAAAEc3NoOg== dummy@gitlab.com
        KEY
      end
    end

    factory :ed25519_sk_key_256 do
      key do
        <<~KEY.delete("\n")
          sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tA
          AAAIEX/dQ0v4127bEo8eeG1EV0ApO2lWbSnN6RWusn/NjqIAAAABHNzaDo= dummy@gitlab.com
        KEY
      end
    end
  end
end
