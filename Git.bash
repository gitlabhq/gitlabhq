language: node_js

node_js:
  - '0.10'

script:
  - ./node_modules/jscoverage/bin/jscoverage src .tmp
  - npm run ci
  - cat ./coverage/coverage.lcov | ./node_modules/coveralls/bin/coveralls.js
