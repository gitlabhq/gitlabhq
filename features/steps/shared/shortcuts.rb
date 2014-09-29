module SharedActiveTab
  include Spinach::DSL

  step 'I press "g" and "p"' do
    find('body').native.send_key('g')
    find('body').native.send_key('p')
  end

  step 'I press "g" and "i"' do
    find('body').native.send_key('g')
    find('body').native.send_key('i')
  end

  step 'I press "g" and "m"' do
    find('body').native.send_key('g')
    find('body').native.send_key('m')
  end
end
