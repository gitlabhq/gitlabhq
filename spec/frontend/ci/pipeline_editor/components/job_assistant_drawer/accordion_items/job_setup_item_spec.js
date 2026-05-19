import JobSetupItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/job_setup_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { JOB_TEMPLATE } from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';

describe('Job setup item', () => {
  let wrapper;

  const findJobNameInput = () => wrapper.findByTestId('job-name-input');
  const findJobScriptInput = () => wrapper.findByTestId('job-script-input');
  const findJobTagsInput = () => wrapper.findByTestId('job-tags-input');
  const findJobStageInput = () => wrapper.findByTestId('job-stage-input');

  const dummyJobName = 'dummyJobName';
  const dummyJobScript = 'dummyJobScript';
  const dummyJobStage = 'dummyJobStage';
  const dummyJobTags = ['tag1'];

  const createComponent = () => {
    wrapper = shallowMountExtended(JobSetupItem, {
      propsData: {
        availableStages: ['.pre', dummyJobStage, '.post'],
        tagOptions: [
          { id: 'tag1', name: 'tag1' },
          { id: 'tag2', name: 'tag2' },
        ],
        isNameValid: true,
        isScriptValid: true,
        job: JSON.parse(JSON.stringify(JOB_TEMPLATE)),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('tags form group accessibility', () => {
    it('passes label-for to the tags form group', () => {
      const tagsFormGroup = wrapper.find('#job-tags-input');
      expect(tagsFormGroup.attributes('label-for')).toBe('job-tags-input-field');
    });

    it('passes text-input-attrs with correct id to the token selector', () => {
      expect(findJobTagsInput().props('textInputAttrs')).toEqual({ id: 'job-tags-input-field' });
    });

    it('does not use aria-labelledby on the token selector', () => {
      expect(findJobTagsInput().attributes('aria-labelledby')).toBeUndefined();
    });
  });

  it('should emit update job event when filling inputs', () => {
    expect(wrapper.emitted('update-job')).toBeUndefined();

    findJobNameInput().vm.$emit('input', dummyJobName);

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toEqual(['name', dummyJobName]);

    findJobScriptInput().vm.$emit('input', dummyJobScript);

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[1]).toEqual(['script', dummyJobScript]);

    findJobStageInput().vm.$emit('input', dummyJobStage);

    expect(wrapper.emitted('update-job')).toHaveLength(3);
    expect(wrapper.emitted('update-job')[2]).toEqual(['stage', dummyJobStage]);

    findJobTagsInput().vm.$emit('input', dummyJobTags);

    expect(wrapper.emitted('update-job')).toHaveLength(4);
    expect(wrapper.emitted('update-job')[3]).toEqual(['tags', dummyJobTags]);
  });
});
