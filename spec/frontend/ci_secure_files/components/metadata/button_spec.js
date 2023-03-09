import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Button from '~/ci_secure_files/components/metadata/button.vue';
import { secureFiles } from '../../mock_data';

const secureFileWithoutMetadata = secureFiles[0];
const secureFileWithMetadata = secureFiles[2];
const modalId = 'metadataModalId';

describe('Secure File Metadata Button', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  const createWrapper = (secureFile = {}, admin = false) => {
    wrapper = mount(Button, {
      propsData: {
        admin,
        modalId,
        secureFile,
      },
    });
  };

  describe('metadata button visibility', () => {
    it.each`
      visibility | admin    | fileName
      ${true}    | ${true}  | ${secureFileWithMetadata}
      ${false}   | ${false} | ${secureFileWithMetadata}
      ${false}   | ${false} | ${secureFileWithoutMetadata}
      ${false}   | ${false} | ${secureFileWithoutMetadata}
    `(
      'button visibility is $visibility when admin equals $admin and $fileName.name is suppled',
      ({ visibility, admin, fileName }) => {
        createWrapper(fileName, admin);
        expect(findButton().exists()).toBe(visibility);

        if (visibility) {
          expect(findButton().isVisible()).toBe(true);
          expect(findButton().attributes('aria-label')).toBe('View File Metadata');
        }
      },
    );
  });
});
