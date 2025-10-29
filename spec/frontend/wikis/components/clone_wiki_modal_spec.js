import { GlButton, GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CloneWikiModal from '~/wikis/components/clone_wiki_modal.vue';
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
  const findCopySshUrlButton = () => wrapper.findByTestId('wiki-copy-ssh-url-button');
  const findCopyHttpUrlButton = () => wrapper.findByTestId('wiki-copy-http-url-button');

  describe('copy buttons', () => {
    it('copy ssh url button renders successfully', () => {
      createComponent();

      expect(findCopySshUrlButton().exists()).toBe(true);
      expect(findCopySshUrlButton().props('text')).toBe('git clone ssh://clone.url/path');
    });

    it('copy http url button renders successfully', () => {
      createComponent();

      expect(findCopyHttpUrlButton().exists()).toBe(true);
      expect(findCopyHttpUrlButton().props('text')).toBe('git clone http://clone.url/path');
    });
  });

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
