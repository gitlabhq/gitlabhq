import { Document, parseDocument } from 'yaml';
import PagesWizardTemplate from '~/pipeline_wizard/templates/pages.yml';
import { merge } from '~/lib/utils/yaml';

const VAR_BUILD_IMAGE = '$BUILD_IMAGE';
const VAR_INSTALLATION_STEPS = '$INSTALLATION_STEPS';
const VAR_BUILD_STEPS = '$BUILD_STEPS';

const getYaml = () => parseDocument(PagesWizardTemplate);
const getFinalTemplate = () => {
  const merged = new Document();
  const yaml = getYaml();
  yaml.toJS().steps.forEach((_, i) => {
    merge(merged, yaml.getIn(['steps', i, 'template']));
  });
  return merged;
};

describe('Pages Template', () => {
  it('is valid yaml', () => {
    // Testing equality to an empty array (as opposed to just comparing
    // errors.length) will cause jest to print the underlying error
    expect(getYaml().errors).toEqual([]);
  });

  it('includes all `target`s in the respective `template`', () => {
    const yaml = getYaml();
    const actual = yaml.toJS().steps.map((x, i) => ({
      inputs: x.inputs,
      template: yaml.getIn(['steps', i, 'template']).toString(),
    }));

    expect(actual).toEqual([
      {
        inputs: [
          expect.objectContaining({
            label: 'Select your build image',
            target: VAR_BUILD_IMAGE,
          }),
          expect.objectContaining({
            widget: 'checklist',
            items: [
              expect.objectContaining({
                text: 'The application files are in the `public` folder',
              }),
            ],
          }),
        ],
        template: expect.stringContaining(VAR_BUILD_IMAGE),
      },
      {
        inputs: [
          expect.objectContaining({
            label: 'Installation Steps',
            target: VAR_INSTALLATION_STEPS,
          }),
        ],
        template: expect.stringContaining(VAR_INSTALLATION_STEPS),
      },
      {
        inputs: [
          expect.objectContaining({
            label: 'Build Steps',
            target: VAR_BUILD_STEPS,
          }),
        ],
        template: expect.stringContaining(VAR_BUILD_STEPS),
      },
    ]);
  });

  it('addresses all relevant instructions for a pages pipeline', () => {
    const fullTemplate = getFinalTemplate();

    expect(fullTemplate.toString()).toEqual(
      `# The Docker image that will be used to build your app
image: ${VAR_BUILD_IMAGE}
# Functions that should be executed before the build script is run
before_script: ${VAR_INSTALLATION_STEPS}
pages:
  script: ${VAR_BUILD_STEPS}
  artifacts:
    paths:
      # The folder that contains the files to be exposed at the Page URL
      - public
  rules:
    # This ensures that only pushes to the default branch will trigger
    # a pages deploy
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
`,
    );
  });
});
