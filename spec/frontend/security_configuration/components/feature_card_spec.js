import { GlCard, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { securityFeatures } from 'jest/security_configuration/mock_data';
import FeatureCard from '~/security_configuration/components/feature_card.vue';
import FeatureCardBadge from '~/security_configuration/components/feature_card_badge.vue';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import { REPORT_TYPE_SAST, REPORT_TYPE_SAST_IAC } from '~/vue_shared/security_reports/constants';
import { manageViaMRErrorMessage } from '../constants';
import { makeFeature } from './utils';

describe('FeatureCard component', () => {
  let feature;
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(FeatureCard, {
      propsData,
      stubs: {
        ManageViaMr: true,
        FeatureCardBadge: true,
        GlCard,
      },
    });
  };

  const findLinks = ({ text, href, isButton = true }) =>
    wrapper
      .findAllComponents(isButton ? GlButton : GlLink)
      .filter((link) => link.text() === text && link.attributes('href') === href);

  const findBadge = () => wrapper.findComponent(FeatureCardBadge);

  const findEnableLinks = () =>
    findLinks({
      text: `Enable ${feature.shortName ?? feature.name}`,
      href: feature.configurationPath,
    });
  const findConfigureLinks = () =>
    findLinks({
      text: `Configure ${feature.shortName ?? feature.name}`,
      href: feature.configurationPath,
    });
  const findManageViaMr = () => wrapper.findComponent(ManageViaMr);
  const findConfigGuideLinks = () =>
    findLinks({ text: 'Configuration guide', href: feature.configurationHelpPath });

  const findSecondarySection = () => wrapper.findByTestId('secondary-feature');

  const findFeatureStatus = () => wrapper.findByTestId('feature-status');

  const expectAction = (action) => {
    const expectEnableAction = action === 'enable';
    const expectConfigureAction = action === 'configure';
    const expectCreateMrAction = action === 'create-mr';
    const expectGuideAction = action === 'guide';

    const enableLinks = findEnableLinks();

    if (expectEnableAction) {
      expect(enableLinks).toHaveLength(1);
      expect(enableLinks.at(0).props('category')).toBe('secondary');
    }

    const configureLinks = findConfigureLinks();

    if (expectConfigureAction) {
      expect(configureLinks).toHaveLength(1);
      expect(configureLinks.at(0).props('category')).toBe('secondary');
    }

    const manageViaMr = findManageViaMr();
    expect(manageViaMr.exists()).toBe(expectCreateMrAction);
    if (expectCreateMrAction) {
      expect(manageViaMr.props('feature')).toBe(feature);
    }

    const configGuideLinks = findConfigGuideLinks();

    if (expectGuideAction) {
      expect(configGuideLinks).toHaveLength(1);
    }
  };

  afterEach(() => {
    feature = undefined;
  });

  describe('basic structure', () => {
    beforeEach(() => {
      feature = makeFeature({
        type: 'sast',
        available: true,
        canEnableByMergeRequest: true,
      });
      createComponent({ feature });
    });

    it('shows the name', () => {
      expect(wrapper.text()).toContain(feature.name);
    });

    it('shows the description', () => {
      expect(wrapper.text()).toContain(feature.description);
    });

    it('shows the help link', () => {
      const links = findLinks({ text: 'Learn more.', href: feature.helpPath, isButton: false });

      expect(links).toHaveLength(1);
    });

    it('should catch and emit manage-via-mr-error', () => {
      findManageViaMr().vm.$emit('error', manageViaMRErrorMessage);
      expect(wrapper.emitted('error')).toEqual([[manageViaMRErrorMessage]]);
    });
  });

  describe('status', () => {
    describe.each`
      context                                         | available | configured   | expectedStatus
      ${'a configured feature'}                       | ${true}   | ${true}      | ${'Enabled'}
      ${'an unconfigured feature'}                    | ${true}   | ${false}     | ${'Not enabled'}
      ${'an unavailable feature'}                     | ${false}  | ${false}     | ${'Available with Ultimate'}
      ${'an unavailable feature with unknown status'} | ${false}  | ${undefined} | ${'Available with Ultimate'}
    `('given $context', ({ available, configured, expectedStatus }) => {
      beforeEach(() => {
        feature = makeFeature({ available, configured });
        createComponent({ feature });
      });

      it(`shows the status "${expectedStatus}"`, () => {
        expect(findFeatureStatus().text()).toBe(expectedStatus);
      });

      if (configured) {
        it('shows a success icon', () => {
          expect(wrapper.findComponent(GlIcon).props('name')).toBe('check-circle-filled');
        });
      }
    });
  });

  describe('actions', () => {
    describe.each`
      context                                            | type                | available | configured | configurationHelpPath | configurationPath | canEnableByMergeRequest | action
      ${'unavailable'}                                   | ${REPORT_TYPE_SAST} | ${false}  | ${false}   | ${'/help'}            | ${null}           | ${false}                | ${null}
      ${'available, no configurationHelpPath'}           | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${null}               | ${null}           | ${false}                | ${null}
      ${'available'}                                     | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${'/help'}            | ${null}           | ${false}                | ${'guide'}
      ${'configured'}                                    | ${REPORT_TYPE_SAST} | ${true}   | ${true}    | ${'/help'}            | ${null}           | ${false}                | ${'guide'}
      ${'available, can enable by MR'}                   | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${'/help'}            | ${null}           | ${true}                 | ${'create-mr'}
      ${'available, can enable by MR, unknown type'}     | ${'foo'}            | ${true}   | ${false}   | ${'/help'}            | ${null}           | ${true}                 | ${'guide'}
      ${'configured, can enable by MR'}                  | ${REPORT_TYPE_SAST} | ${true}   | ${true}    | ${'/help'}            | ${null}           | ${true}                 | ${'guide'}
      ${'available with config path'}                    | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${'/help'}            | ${'foo'}          | ${false}                | ${'enable'}
      ${'available with config path, can enable by MR'}  | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${'/help'}            | ${'foo'}          | ${true}                 | ${'enable'}
      ${'configured with config path'}                   | ${REPORT_TYPE_SAST} | ${true}   | ${true}    | ${'/help'}            | ${'foo'}          | ${false}                | ${'configure'}
      ${'configured with config path, can enable by MR'} | ${REPORT_TYPE_SAST} | ${true}   | ${true}    | ${'/help'}            | ${'foo'}          | ${true}                 | ${'configure'}
    `(
      'given $context feature',
      ({
        type,
        available,
        configured,
        configurationHelpPath,
        configurationPath,
        canEnableByMergeRequest,
        action,
      }) => {
        beforeEach(() => {
          feature = makeFeature({
            type,
            available,
            configured,
            configurationHelpPath,
            configurationPath,
            canEnableByMergeRequest,
          });
          createComponent({ feature });
        });

        it(`shows ${action} action`, () => {
          expectAction(action);
        });
      },
    );
  });

  describe('secondary feature', () => {
    describe('basic structure', () => {
      describe('given no secondary', () => {
        beforeEach(() => {
          feature = makeFeature();
          createComponent({ feature });
        });

        it('does not show a secondary feature', () => {
          expect(findSecondarySection().exists()).toBe(false);
        });
      });

      describe('given a secondary', () => {
        beforeEach(() => {
          feature = makeFeature({
            secondary: {
              name: 'secondary name',
              description: 'secondary description',
              configurationText: 'manage secondary',
            },
          });
          createComponent({ feature });
        });

        it('shows a secondary feature', () => {
          const secondaryText = findSecondarySection().text();
          expect(secondaryText).toContain(feature.secondary.name);
          expect(secondaryText).toContain(feature.secondary.description);
        });
      });
    });

    describe('actions', () => {
      describe('given available feature with secondary', () => {
        beforeEach(() => {
          feature = makeFeature({
            available: true,
            secondary: {
              name: 'secondary name',
              description: 'secondary description',
              configurationPath: '/secondary',
              configurationText: 'manage secondary',
            },
          });
          createComponent({ feature });
        });

        it('shows the secondary action', () => {
          const links = findLinks({
            text: feature.secondary.configurationText,
            href: feature.secondary.configurationPath,
          });

          expect(links).toHaveLength(1);
        });
      });

      describe.each`
        context                                    | available | secondaryConfigPath
        ${'available feature without config path'} | ${true}   | ${null}
        ${'unavailable feature with config path'}  | ${false}  | ${'/secondary'}
      `('given $context', ({ available, secondaryConfigPath }) => {
        beforeEach(() => {
          feature = makeFeature({
            available,
            secondary: {
              name: 'secondary name',
              description: 'secondary description',
              configurationPath: secondaryConfigPath,
              configurationText: 'manage secondary',
            },
          });
          createComponent({ feature });
        });

        it('does not show the secondary action', () => {
          const links = findLinks({
            text: feature.secondary.configurationText,
            href: feature.secondary.configurationPath,
          });
          expect(links.exists()).toBe(false);
        });
      });

      describe('given an available secondary with a configuration guide', () => {
        beforeEach(() => {
          feature = makeFeature({
            available: true,
            configurationHelpPath: null,
            secondary: {
              name: 'secondary name',
              description: 'secondary description',
              configurationHelpPath: '/secondary',
              configurationText: null,
            },
          });
          createComponent({ feature });
        });

        it('shows the secondary action', () => {
          const links = findLinks({
            text: 'Configuration guide',
            href: feature.secondary.configurationHelpPath,
          });

          expect(links).toHaveLength(1);
        });
      });

      describe('given an unavailable secondary with a configuration guide', () => {
        beforeEach(() => {
          feature = makeFeature({
            available: false,
            configurationHelpPath: null,
            secondary: {
              name: 'secondary name',
              description: 'secondary description',
              configurationHelpPath: '/secondary',
              configurationText: null,
            },
          });
          createComponent({ feature });
        });

        it('does not show the secondary action', () => {
          const links = findLinks({
            text: 'Configuration guide',
            href: feature.secondary.configurationHelpPath,
          });
          expect(links.exists()).toBe(false);
          expect(links).toHaveLength(0);
        });
      });
    });

    describe('information badge', () => {
      describe.each`
        context                                 | available | badge
        ${'available feature with badge'}       | ${true}   | ${{ text: 'test' }}
        ${'unavailable feature without badge'}  | ${false}  | ${null}
        ${'available feature without badge'}    | ${true}   | ${null}
        ${'unavailable feature with badge'}     | ${false}  | ${{ text: 'test' }}
        ${'available feature with empty badge'} | ${false}  | ${{}}
      `('given $context', ({ available, badge }) => {
        beforeEach(() => {
          feature = makeFeature({
            available,
            badge,
          });
          createComponent({ feature });
        });

        it('should show badge when badge given in configuration and available', () => {
          expect(findBadge().exists()).toBe(Boolean(available && badge && badge.text));
        });
      });
    });
  });

  describe('SAST IaC status and badge', () => {
    describe.each`
      context                            | available | configured | expectedStatus
      ${'configured SAST IaC feature'}   | ${true}   | ${true}    | ${'Enabled'}
      ${'unavailable SAST IaC feature'}  | ${false}  | ${false}   | ${'Available with Ultimate'}
      ${'unconfigured SAST IaC feature'} | ${true}   | ${false}   | ${'Not enabled'}
    `('given $context', ({ available, configured, expectedStatus }) => {
      beforeEach(() => {
        const securityFeature = securityFeatures.find(({ type }) => REPORT_TYPE_SAST_IAC === type);
        feature = { ...securityFeature, available, configured };
        createComponent({ feature });
      });

      it(`shows the status "${expectedStatus}"`, () => {
        expect(findFeatureStatus().text()).toBe(expectedStatus);
      });

      if (configured) {
        it('shows a success icon', () => {
          expect(wrapper.findComponent(GlIcon).props('name')).toBe('check-circle-filled');
        });
      }
    });
  });
});
