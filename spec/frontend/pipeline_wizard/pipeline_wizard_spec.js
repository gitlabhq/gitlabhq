import { parseDocument } from 'yaml';
import PipelineWizard from '~/pipeline_wizard/pipeline_wizard.vue';
import PipelineWizardWrapper from '~/pipeline_wizard/components/wrapper.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  fullTemplate as template,
  fullTemplateWithoutFilename as templateWithoutFilename,
} from './mock/yaml';

const projectPath = 'foo/bar';
const defaultBranch = 'main';

describe('PipelineWizard', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PipelineWizard, {
      propsData: {
        projectPath,
        defaultBranch,
        template,
        ...props,
      },
    });
  };

  it('mounts without error', () => {
    const consoleSpy = jest.spyOn(console, 'error');

    createComponent();

    expect(consoleSpy).not.toHaveBeenCalled();
    expect(wrapper.exists()).toBe(true);
  });

  it('mounts the wizard wrapper', () => {
    createComponent();

    expect(wrapper.findComponent(PipelineWizardWrapper).exists()).toBe(true);
  });

  it('passes the correct steps prop to the wizard wrapper', () => {
    createComponent();

    expect(wrapper.findComponent(PipelineWizardWrapper).props('steps')).toEqual(
      parseDocument(template).get('steps'),
    );
  });

  it('passes all other expected props to the wizard wrapper', () => {
    createComponent();

    expect(wrapper.findComponent(PipelineWizardWrapper).props()).toEqual(
      expect.objectContaining({
        defaultBranch,
        projectPath,
        filename: parseDocument(template).get('filename'),
        templateId: parseDocument(template).get('id'),
      }),
    );
  });

  it('passes ".gitlab-ci.yml" as default filename to the wizard wrapper', () => {
    createComponent({ template: templateWithoutFilename });

    expect(wrapper.findComponent(PipelineWizardWrapper).attributes('filename')).toBe(
      '.gitlab-ci.yml',
    );
  });

  it('allows overriding the defaultFilename with `defaultFilename` prop', () => {
    const defaultFilename = 'foobar.yml';

    createComponent({
      template: templateWithoutFilename,
      defaultFilename,
    });

    expect(wrapper.findComponent(PipelineWizardWrapper).attributes('filename')).toBe(
      defaultFilename,
    );
  });

  it('displays the title', () => {
    createComponent();

    expect(wrapper.findByTestId('title').text()).toBe(
      parseDocument(template).get('title').toString(),
    );
  });

  it('displays the description', () => {
    createComponent();

    expect(wrapper.findByTestId('description').text()).toBe(
      parseDocument(template).get('description').toString(),
    );
  });

  it('bubbles the done event upwards', () => {
    createComponent();

    wrapper.findComponent(PipelineWizardWrapper).vm.$emit('done');

    expect(wrapper.emitted().done.length).toBe(1);
  });
});
