import { GlButton, GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CloneWikiModal from '~/pages/shared/wikis/components/clone_wiki_modal.vue';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';

describe('DeleteWikiModal', () => {
  let wrapper;
  let glModalDirective;

  const createComponent = (propsData = {}) => {
    glModalDirective = jest.fn();

    wrapper = shallowMountExtended(CloneWikiModal, {
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      provide: {
        wikiPath: 'wiki-path',
        cloneSshUrl: 'ssh://clone.url/path',
        cloneHttpUrl: 'http://clone.url/path',
      },
      propsData: { ...propsData },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findCloneModal = () => wrapper.findComponent(GlModal);
  const findModalTitle = () => wrapper.findByTestId('wiki-clone-modal-title');
  const findCloneButtonTrigger = () => wrapper.findComponent(GlButton);
  const findCloneListTrigger = () => wrapper.findComponent(GlDisclosureDropdownItem);

  it('renders a modal', () => {
    const modalId = 'clone-wiki-modal';

    createComponent();

    expect(findCloneModal().props('modalId')).toBe(modalId);
    expect(glModalDirective).toHaveBeenCalledWith(modalId);
  });

  it('shows correct title', () => {
    createComponent();

    expect(findModalTitle().text()).toBe('Clone repository');
  });

  describe('setting `showAsDropdownItem`', () => {
    it('to false renders as button', () => {
      createComponent();

      expect(findCloneButtonTrigger().exists()).toBe(true);
      expect(findCloneListTrigger().exists()).toBe(false);
    });

    it('to true renders as list item', () => {
      createComponent({ showAsDropdownItem: true });

      expect(findCloneListTrigger().exists()).toBe(true);
      expect(findCloneButtonTrigger().exists()).toBe(false);
    });
  });
});
