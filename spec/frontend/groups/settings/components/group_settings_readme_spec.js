import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupSettingsReadme from '~/groups/settings/components/group_settings_readme.vue';
import { GITLAB_README_PROJECT } from '~/groups/settings/constants';
import {
  MOCK_GROUP_PATH,
  MOCK_GROUP_ID,
  MOCK_PATH_TO_GROUP_README,
  MOCK_PATH_TO_README_PROJECT,
} from '../mock_data';

describe('GroupSettingsReadme', () => {
  let wrapper;

  const defaultProps = {
    groupPath: MOCK_GROUP_PATH,
    groupId: MOCK_GROUP_ID,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GroupSettingsReadme, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlModal,
        GlSprintf,
      },
    });
  };

  const findHasReadmeButtonLink = () => wrapper.findByText('README');
  const findAddReadmeButton = () => wrapper.findByTestId('group-settings-add-readme-button');
  const findModalBody = () => wrapper.findByTestId('group-settings-modal-readme-body');
  const findModalCreateReadmeButton = () =>
    wrapper.findByTestId('group-settings-modal-create-readme-button');

  describe('Group has existing README', () => {
    beforeEach(() => {
      createComponent({
        groupReadmePath: MOCK_PATH_TO_GROUP_README,
        readmeProjectPath: MOCK_PATH_TO_README_PROJECT,
      });
    });

    describe('template', () => {
      it('renders README Button Link with correct path and text', () => {
        expect(findHasReadmeButtonLink().exists()).toBe(true);
        expect(findHasReadmeButtonLink().attributes('href')).toBe(MOCK_PATH_TO_GROUP_README);
      });

      it('does not render Add README Button', () => {
        expect(findAddReadmeButton().exists()).toBe(false);
      });
    });
  });

  describe('Group has README project without README file', () => {
    beforeEach(() => {
      createComponent({ readmeProjectPath: MOCK_PATH_TO_README_PROJECT });
    });

    describe('template', () => {
      it('does not render README', () => {
        expect(findHasReadmeButtonLink().exists()).toBe(false);
      });

      it('does render Add Readme Button with correct text', () => {
        expect(findAddReadmeButton().exists()).toBe(true);
        expect(findAddReadmeButton().text()).toBe('Add README');
      });

      it('generates a hidden modal with correct body text', () => {
        expect(findModalBody().text()).toMatchInterpolatedText(
          `This will create a README.md for project ${MOCK_PATH_TO_README_PROJECT}.`,
        );
      });

      it('generates a hidden modal with correct button text', () => {
        expect(findModalCreateReadmeButton().text()).toBe('Add README');
      });
    });
  });

  describe('Group does not have README project', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('template', () => {
      it('does not render README', () => {
        expect(findHasReadmeButtonLink().exists()).toBe(false);
      });

      it('does render Add Readme Button with correct text', () => {
        expect(findAddReadmeButton().exists()).toBe(true);
        expect(findAddReadmeButton().text()).toBe('Add README');
      });

      it('generates a hidden modal with correct body text', () => {
        expect(findModalBody().text()).toMatchInterpolatedText(
          `This will create a project ${MOCK_GROUP_PATH}/${GITLAB_README_PROJECT} and add a README.md.`,
        );
      });

      it('generates a hidden modal with correct button text', () => {
        expect(findModalCreateReadmeButton().text()).toBe('Create and add README');
      });
    });
  });
});
