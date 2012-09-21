## Development tips: 

### Start application in development mode

#### 1. Via foreman 

    bundle exec foreman -p 3000

#### 2. Via gitlab cli

    ./gitlab start

#### 3. Manually

   bundle exec rails s
   bundle exec rake environment resque:work QUEUE=* VVERBOSE=1


### Run tests: 
 
#### 1. Packages

    # ubuntu
    sudo apt-get install libqt4-dev libqtwebkit-dev
    sudo apt-get install xvfb
   
    # Mac 
    brew install qt
    brew install xvfb

#### 2. DB & seeds

    bundle exec rake db:setup RAILS_ENV=test
    bundle exec rake db:seed_fu RAILS_ENV=test

###  3. Run Tests

    # All in one
    bundle exec rake gitlab:test
    
    # Rspec 
    bundle exec rake spec
    
    # Spinach
    bundle exec rake spinach
