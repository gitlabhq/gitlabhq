import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

import Modal from '~/ci_secure_files/components/metadata/modal.vue';

import { secureFiles } from '../../mock_data';

const cerFile = secureFiles[2];
const mobileprovisionFile = secureFiles[3];
const modalId = 'metadataModalId';

describe('Secure File Metadata Modal', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (secureFile = {}) => {
    wrapper = mount(Modal, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
      propsData: {
        modalId,
        name: secureFile.name,
        metadata: secureFile.metadata,
        fileExtension: secureFile.file_extension,
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('when a .cer file is supplied', () => {
    it('matches cer the snapshot', () => {
      createWrapper(cerFile);
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when a .mobileprovision file is supplied', () => {
    it('matches the mobileprovision snapshot', () => {
      createWrapper(mobileprovisionFile);
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('event tracking', () => {
    it('sends cer tracking information when the modal is loaded', () => {
      createWrapper(cerFile);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'load_secure_file_metadata_cer', {});
      expect(trackingSpy).not.toHaveBeenCalledWith(
        undefined,
        'load_secure_file_metadata_mobileprovision',
        {},
      );
    });

    it('sends mobileprovision tracking information when the modal is loaded', () => {
      createWrapper(mobileprovisionFile);
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        'load_secure_file_metadata_mobileprovision',
        {},
      );
      expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'load_secure_file_metadata_cer', {});
    });
  });
});
