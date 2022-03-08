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
