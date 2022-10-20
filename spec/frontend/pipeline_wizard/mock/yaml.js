export const stepInputs = `
- label: "Build Steps"
  description: "Enter the steps necessary for your application."
  widget: text
  target: $BUILD_STEPS
- label: "Select a deployment branch"
  description: "Select the branch we should use to generate your site from."
  widget: text
  target: $BRANCH
  pattern: "^[a-z]+$"
  invalidFeedback: "This field may only contain lowercase letters"
  required: true
`;

export const stepTemplate = `template:
  pages:
    script: $BUILD_STEPS
    artifacts:
      paths:
        - public
    only:
      - $BRANCH
`;

export const compiledYamlBeforeSetup = `abc: def`;

export const compiledYamlAfterInitialLoad = `abc: def
pages:
  script: $BUILD_STEPS
  artifacts:
    paths:
      - public
  only:
    - $BRANCH
`;

export const compiledYaml = `abc: def
pages:
  script: foo
  artifacts:
    paths:
      - public
  only:
    - bar
`;

export const steps = `
- inputs:
    - label: foo
      target: $FOO
      widget: text
  template:
    foo: $FOO
- inputs:
    - label: bar
      target: $BAR
      widget: text
  template:
    bar: $BAR
`;

export const compiledScenario1 = `foo: fooVal
`;

export const compiledScenario2 = `bar: barVal
`;

export const compiledScenario3 = `foo: newFooVal
bar: barVal
`;

export const fullTemplate = `
id: test/full-template
title: some title
description: some description
filename: foo.yml
steps:
  - inputs:
     - widget: text
       label: foo
       target: $BAR
    template:
      foo: $BAR
`;

export const fullTemplateWithoutFilename = `
id: test/full-template-no-filename
title: some title
description: some description
steps:
  - inputs:
     - widget: text
       label: foo
       target: $BAR
    template:
      foo: $BAR
`;
