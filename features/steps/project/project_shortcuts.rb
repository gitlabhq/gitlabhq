class Spinach::Features::ProjectShortcuts < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedProjectTab

  step 'I press "g" and "f"' do
    find('body').native.send_key('g')
    find('body').native.send_key('f')
  end

  step 'I press "g" and "c"' do
    find('body').native.send_key('g')
    find('body').native.send_key('c')
  end

  step 'I press "g" and "n"' do
    find('body').native.send_key('g')
    find('body').native.send_key('n')
  end

  step 'I press "g" and "g"' do
    find('body').native.send_key('g')
    find('body').native.send_key('g')
  end

  step 'I press "g" and "s"' do
    find('body').native.send_key('g')
    find('body').native.send_key('s')
  end

  step 'I press "g" and "w"' do
    find('body').native.send_key('g')
    find('body').native.send_key('w')
  end

  step 'I press "g" and "e"' do
    find('body').native.send_key('g')
    find('body').native.send_key('e')
  end
end
