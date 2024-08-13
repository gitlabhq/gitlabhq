import { GlButton, GlModal, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PruneObjectsButton from '~/projects/prune_unreachable_objects_button.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('Project remove modal', () => {
  let wrapper;

  const findFormElement = () => wrapper.find('form');
  const findAuthenticityTokenInput = () => findFormElement().find('input[name=authenticity_token]');
  const findModal = () => wrapper.findComponent(GlModal);
  const findBtn = () => wrapper.findComponent(GlButton);
  const defaultProps = {
    pruneObjectsPath: 'prunepath',
    pruneObjectsDocPath: 'prunedocspath',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(PruneObjectsButton, {
      propsData: defaultProps,
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
    });
  };

  describe('intialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets a csrf token on the authenticity form input', () => {
      expect(findAuthenticityTokenInput().element.value).toEqual('test-csrf-token');
    });

    it('sets the form action to the provided path', () => {
      expect(findFormElement().attributes('action')).toEqual(defaultProps.pruneObjectsPath);
    });

    it('sets the documentation link to the provided path', () => {
      expect(findModal().findComponent(GlLink).attributes('href')).toEqual(
        defaultProps.pruneObjectsDocPath,
      );
    });

    it('button opens modal', () => {
      const buttonModalDirective = getBinding(findBtn().element, 'gl-modal');

      expect(findModal().props('modalId')).toBe(buttonModalDirective.value);
      expect(findModal().text()).toContain('Are you sure you want to prune?');
    });
  });

  describe('when the modal is confirmed', () => {
    beforeEach(() => {
      createComponent();
      findModal().vm.$emit('ok');
    });

    it('submits the form element', () => {
      expect(findFormElement().element.submit).toHaveBeenCalled();
    });
  });
});
