import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import KeepLatestArtifactCheckbox from '~/artifacts_settings/keep_latest_artifact_checkbox.vue';
import UpdateKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/mutations/update_keep_latest_artifact_project_setting.mutation.graphql';

describe('Keep latest artifact checkbox', () => {
  let wrapper;

  const mutate = jest.fn().mockResolvedValue();
  const fullPath = 'gitlab-org/gitlab';
  const helpPagePath = '/help/ci/pipelines/job_artifacts';

  const findCheckbox = () => wrapper.find(GlFormCheckbox);
  const findHelpLink = () => wrapper.find(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(KeepLatestArtifactCheckbox, {
      provide: {
        fullPath,
        helpPagePath,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the checkbox and the help link', () => {
    expect(findCheckbox().exists()).toBe(true);
    expect(findHelpLink().exists()).toBe(true);
  });

  it('sets correct setting value in checkbox with query result', async () => {
    await wrapper.setData({ keepLatestArtifact: true });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('calls mutation on artifact setting change with correct payload', () => {
    findCheckbox().vm.$emit('change', false);

    const expected = {
      mutation: UpdateKeepLatestArtifactProjectSetting,
      variables: {
        fullPath,
        keepLatestArtifact: false,
      },
    };

    expect(mutate).toHaveBeenCalledWith(expected);
  });
});
