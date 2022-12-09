import { GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { sprintf } from '~/locale';
import SecurityPatchUpgradeAlertModal from '~/gitlab_version_check/components/security_patch_upgrade_alert_modal.vue';
import * as utils from '~/gitlab_version_check/utils';
import {
  UPGRADE_DOCS_URL,
  ABOUT_RELEASES_PAGE,
  TRACKING_ACTIONS,
  TRACKING_LABELS,
} from '~/gitlab_version_check/constants';

describe('SecurityPatchUpgradeAlertModal', () => {
  let wrapper;
  let trackingSpy;

  const defaultProps = {
    currentVersion: '11.1.1',
  };

  const createComponent = (props = {}) => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

    wrapper = shallowMountExtended(SecurityPatchUpgradeAlertModal, {
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

  afterEach(() => {
    unmockTracking();
  });

  const expectDispatchedTracking = (action, label) => {
    expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
      label,
      property: defaultProps.currentVersion,
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlModalTitle = () => wrapper.findByTestId('alert-modal-title');
  const findGlModalBody = () => wrapper.findByTestId('alert-modal-body');
  const findGlModalDetails = () => wrapper.findByTestId('alert-modal-details');
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findGlRemindButton = () => wrapper.findByTestId('alert-modal-remind-button');
  const findGlUpgradeButton = () => wrapper.findByTestId('alert-modal-upgrade-button');

  describe('template defaults', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders visible critical security alert modal', () => {
      expect(findGlModal().props('visible')).toBe(true);
    });

    it('renders the modal title correctly', () => {
      expect(findGlModalTitle().text()).toBe(wrapper.vm.$options.i18n.modalTitle);
    });

    it('renders modal body without suggested versions', () => {
      expect(findGlModalBody().text()).toBe(
        sprintf(wrapper.vm.$options.i18n.modalBodyNoStableVersions, {
          currentVersion: defaultProps.currentVersion,
        }),
      );
    });

    it('does not render modal details', () => {
      expect(findGlModalDetails().exists()).toBe(false);
    });

    it(`tracks render ${TRACKING_LABELS.MODAL} correctly`, () => {
      expectDispatchedTracking(TRACKING_ACTIONS.RENDER, TRACKING_LABELS.MODAL);
    });

    it(`tracks click ${TRACKING_LABELS.DISMISS} when close button clicked`, async () => {
      await findGlModal().vm.$emit('close');

      expectDispatchedTracking(TRACKING_ACTIONS.CLICK_BUTTON, TRACKING_LABELS.DISMISS);
    });

    describe('Learn more link', () => {
      it('renders with correct text and link', () => {
        expect(findGlLink().text()).toBe(wrapper.vm.$options.i18n.learnMore);
        expect(findGlLink().attributes('href')).toBe(ABOUT_RELEASES_PAGE);
      });

      it(`tracks click ${TRACKING_LABELS.LEARN_MORE_LINK} when clicked`, async () => {
        await findGlLink().vm.$emit('click');

        expectDispatchedTracking(TRACKING_ACTIONS.CLICK_LINK, TRACKING_LABELS.LEARN_MORE_LINK);
      });
    });

    describe('Remind me button', () => {
      beforeEach(() => {
        wrapper.vm.$refs.alertModal.hide = jest.fn();
      });

      it('renders with correct text', () => {
        expect(findGlRemindButton().text()).toBe(wrapper.vm.$options.i18n.secondaryButtonText);
      });

      it(`tracks click ${TRACKING_LABELS.REMIND_ME_BTN} when clicked`, async () => {
        await findGlRemindButton().vm.$emit('click');

        expectDispatchedTracking(TRACKING_ACTIONS.CLICK_BUTTON, TRACKING_LABELS.REMIND_ME_BTN);
      });

      it('calls setHideAlertModalCookie with the currentVersion when clicked', async () => {
        jest.spyOn(utils, 'setHideAlertModalCookie');
        await findGlRemindButton().vm.$emit('click');

        expect(utils.setHideAlertModalCookie).toHaveBeenCalledWith(defaultProps.currentVersion);
      });

      it('hides the modal', async () => {
        await findGlRemindButton().vm.$emit('click');

        expect(wrapper.vm.$refs.alertModal.hide).toHaveBeenCalled();
      });
    });

    describe('Upgrade button', () => {
      it('renders with correct text and link', () => {
        expect(findGlUpgradeButton().text()).toBe(wrapper.vm.$options.i18n.primaryButtonText);
        expect(findGlUpgradeButton().attributes('href')).toBe(UPGRADE_DOCS_URL);
      });

      it(`tracks click ${TRACKING_LABELS.UPGRADE_BTN_LINK} when clicked`, async () => {
        await findGlUpgradeButton().vm.$emit('click');

        expectDispatchedTracking(TRACKING_ACTIONS.CLICK_LINK, TRACKING_LABELS.UPGRADE_BTN_LINK);
      });

      it('calls setHideAlertModalCookie with the currentVersion when clicked', async () => {
        jest.spyOn(utils, 'setHideAlertModalCookie');
        await findGlUpgradeButton().vm.$emit('click');

        expect(utils.setHideAlertModalCookie).toHaveBeenCalledWith(defaultProps.currentVersion);
      });
    });
  });

  describe('template with latestStableVersions', () => {
    const latestStableVersions = ['88.8.3', '89.9.9', '90.0.0'];

    beforeEach(() => {
      createComponent({ latestStableVersions });
    });

    it('renders modal body with suggested versions', () => {
      expect(findGlModalBody().text()).toBe(
        sprintf(wrapper.vm.$options.i18n.modalBodyStableVersions, {
          currentVersion: defaultProps.currentVersion,
          latestStableVersions: latestStableVersions.join(', '),
        }),
      );
    });
  });

  describe('template with details', () => {
    const details = 'This is some details about the upgrade';

    beforeEach(() => {
      createComponent({ details });
    });

    it('renders modal details', () => {
      expect(findGlModalDetails().text()).toBe(
        sprintf(wrapper.vm.$options.i18n.modalDetails, { details }),
      );
    });
  });

  describe('when modal is hidden by cookie', () => {
    beforeEach(() => {
      jest.spyOn(utils, 'getHideAlertModalCookie').mockReturnValue(true);
      createComponent();
    });

    it('renders modal with visibility false', () => {
      expect(findGlModal().props('visible')).toBe(false);
    });

    it(`does not track render ${TRACKING_LABELS.MODAL} correctly`, () => {
      expect(trackingSpy).not.toHaveBeenCalledWith(undefined, TRACKING_ACTIONS.RENDER, {
        label: TRACKING_LABELS.MODAL,
        property: defaultProps.currentVersion,
      });
    });
  });
});
