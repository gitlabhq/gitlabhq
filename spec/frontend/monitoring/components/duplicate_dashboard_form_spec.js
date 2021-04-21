import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';

import { dashboardGitResponse } from '../mock_data';

let wrapper;

const createMountedWrapper = (props = {}) => {
  // Use `mount` to render native input elements
  wrapper = mount(DuplicateDashboardForm, {
    propsData: { ...props },
    // We need to attach to document, so that `document.activeElement` is properly set in jsdom
    attachTo: document.body,
  });
};

describe('DuplicateDashboardForm', () => {
  const defaultBranch = 'main';

  const findByRef = (ref) => wrapper.find({ ref });
  const setValue = (ref, val) => {
    findByRef(ref).setValue(val);
  };
  const setChecked = (value) => {
    const input = wrapper.find(`.custom-control-input[value="${value}"]`);
    input.element.checked = true;
    input.trigger('click');
    input.trigger('change');
  };

  beforeEach(() => {
    createMountedWrapper({ dashboard: dashboardGitResponse[0], defaultBranch });
  });

  it('renders correctly', () => {
    expect(wrapper.exists()).toEqual(true);
  });

  it('renders form elements', () => {
    expect(findByRef('fileName').exists()).toEqual(true);
    expect(findByRef('branchName').exists()).toEqual(true);
    expect(findByRef('branchOption').exists()).toEqual(true);
    expect(findByRef('commitMessage').exists()).toEqual(true);
  });

  describe('validates the file name', () => {
    const findInvalidFeedback = () => findByRef('fileNameFormGroup').find('.invalid-feedback');

    it('when is empty', async () => {
      setValue('fileName', '');
      await nextTick();

      expect(findByRef('fileNameFormGroup').classes()).toContain('is-valid');
      expect(findInvalidFeedback().exists()).toBe(false);
    });

    it('when is valid', async () => {
      setValue('fileName', 'my_dashboard.yml');
      await nextTick();

      expect(findByRef('fileNameFormGroup').classes()).toContain('is-valid');
      expect(findInvalidFeedback().exists()).toBe(false);
    });

    it('when is not valid', async () => {
      setValue('fileName', 'my_dashboard.exe');
      await nextTick();

      expect(findByRef('fileNameFormGroup').classes()).toContain('is-invalid');
      expect(findInvalidFeedback().text()).toBeTruthy();
    });
  });

  describe('emits `change` event', () => {
    const lastChange = () =>
      nextTick().then(() => {
        wrapper.find('form').trigger('change');

        // Resolves to the last emitted change
        const changes = wrapper.emitted().change;
        return changes[changes.length - 1][0];
      });

    it('with the inital form values', () => {
      expect(wrapper.emitted().change).toHaveLength(1);

      return expect(lastChange()).resolves.toEqual({
        branch: '',
        commitMessage: expect.any(String),
        dashboard: dashboardGitResponse[0].path,
        fileName: 'common_metrics.yml',
      });
    });

    it('containing an inputted file name', () => {
      setValue('fileName', 'my_dashboard.yml');

      return expect(lastChange()).resolves.toMatchObject({
        fileName: 'my_dashboard.yml',
      });
    });

    it('containing a default commit message when no message is set', () => {
      setValue('commitMessage', '');

      return expect(lastChange()).resolves.toMatchObject({
        commitMessage: expect.stringContaining('Create custom dashboard'),
      });
    });

    it('containing an inputted commit message', () => {
      setValue('commitMessage', 'My commit message');

      return expect(lastChange()).resolves.toMatchObject({
        commitMessage: expect.stringContaining('My commit message'),
      });
    });

    it('containing an inputted branch name', () => {
      setValue('branchName', 'a-new-branch');

      return expect(lastChange()).resolves.toMatchObject({
        branch: 'a-new-branch',
      });
    });

    it('when a `default` branch option is set, branch input is invisible and ignored', () => {
      setChecked(wrapper.vm.$options.radioVals.DEFAULT);
      setValue('branchName', 'a-new-branch');

      return Promise.all([
        expect(lastChange()).resolves.toMatchObject({
          branch: defaultBranch,
        }),
        nextTick(() => {
          expect(findByRef('branchName').isVisible()).toBe(false);
        }),
      ]);
    });

    it('when `new` branch option is chosen, focuses on the branch name input', async () => {
      setChecked(wrapper.vm.$options.radioVals.NEW);

      await nextTick();

      wrapper.find('form').trigger('change');
      expect(document.activeElement).toBe(findByRef('branchName').element);
    });
  });
});

describe('DuplicateDashboardForm escapes elements', () => {
  const branchToEscape = "<img/src='x'onerror=alert(document.domain)>";

  beforeEach(() => {
    createMountedWrapper({ dashboard: dashboardGitResponse[0], defaultBranch: branchToEscape });
  });

  it('should escape branch name data', () => {
    const branchOptionHtml = wrapper.vm.branchOptions[0].html;
    const escapedBranch = '&lt;img/src=&#39;x&#39;onerror=alert(document.domain)&gt';

    expect(branchOptionHtml).toEqual(expect.stringContaining(escapedBranch));
  });
});
