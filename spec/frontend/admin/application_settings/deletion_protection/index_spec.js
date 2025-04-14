import { createWrapper } from '@vue/test-utils';
import { initAdminDeletionProtectionSettings } from '~/admin/application_settings/deletion_protection';
import { parseFormProps } from '~/admin/application_settings/deletion_protection/utils';
import FormGroup from '~/admin/application_settings/deletion_protection/components/form_group.vue';

jest.mock('~/admin/application_settings/deletion_protection/utils', () => ({
  parseFormProps: jest.fn().mockReturnValue({
    deletionAdjournedPeriod: 7,
    delayedGroupDeletion: false,
    delayedProjectDeletion: false,
  }),
}));

describe('initAdminDeletionProtectionSettings', () => {
  let appRoot;
  let wrapper;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('id', 'js-admin-deletion-protection-settings');
    appRoot.dataset.deletionAdjournedPeriod = 7;
    appRoot.dataset.delayedGroupDeletion = false;
    appRoot.dataset.delayedProjectDeletion = false;
    document.body.appendChild(appRoot);
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  const findFormGroup = () => wrapper.findComponent(FormGroup);

  describe('when there is no app root', () => {
    it('returns false', () => {
      expect(initAdminDeletionProtectionSettings()).toBe(false);
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
      wrapper = createWrapper(initAdminDeletionProtectionSettings());
    });

    it('renders FormGroup', () => {
      expect(findFormGroup().exists()).toBe(true);
    });

    it('parses the form props from the dataset', () => {
      expect(parseFormProps).toHaveBeenCalledWith(appRoot.dataset);
    });
  });
});
