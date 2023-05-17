import { GlAlert, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import LockedWarning, { i18n } from '~/issues/show/components/locked_warning.vue';

describe('LockedWarning component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(LockedWarning, {
      propsData: props,
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  describe.each([TYPE_ISSUE, TYPE_EPIC])('with issuableType set to %s', (issuableType) => {
    let alert;
    let link;
    beforeEach(() => {
      createComponent({ issuableType });
      alert = findAlert();
      link = findLink();
    });

    afterEach(() => {
      alert = null;
      link = null;
    });

    it('displays a non-closable alert', () => {
      expect(alert.exists()).toBe(true);
      expect(alert.props('dismissible')).toBe(false);
    });

    it(`displays correct message`, () => {
      expect(alert.text()).toMatchInterpolatedText(sprintf(i18n.alertMessage, { issuableType }));
    });

    it(`displays a link with correct text`, () => {
      expect(link.exists()).toBe(true);
      expect(link.text()).toBe(`the ${issuableType}`);
    });
  });
});
