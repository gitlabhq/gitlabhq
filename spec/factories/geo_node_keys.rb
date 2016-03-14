FactoryGirl.define do
  factory :geo_node_key, class: 'GeoNodeKey' do
    title
    key do
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= dummy@gitlab.com"
    end

    trait :another_key do
      key do
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmTillFzNTrrGgwaCKaSj+QCz81E6jBc/s9av0+3b1Hwfxgkqjl4nAK/OD2NjgyrONDTDfR8cRN4eAAy6nY8GLkOyYBDyuc5nTMqs5z3yVuTwf3koGm/YQQCmo91psZ2BgDFTor8SVEE5Mm1D1k3JDMhDFxzzrOtRYFPci9lskTJaBjpqWZ4E9rDTD2q/QZntCqbC3wE9uSemRQB5f8kik7vD/AD8VQXuzKladrZKkzkONCPWsXDspUitjM8HkQdOf0PsYn1CMUC1xKYbCxkg5TkEosIwGv6CoEArUrdu/4+10LVslq494mAvEItywzrluCLCnwELfW+h/m8UHoVhZ"
      end
    end
  end
end
