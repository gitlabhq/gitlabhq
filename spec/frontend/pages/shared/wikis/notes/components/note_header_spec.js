import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import NoteHeader from '~/pages/shared/wikis/wiki_notes/components/note_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('NoteHeader', () => {
  let wrapper;

  const author = {
    id: 1,
    name: 'John Doe',
    username: 'johndoe',
    path: '/johndoe',
    webUrl: 'https://example.com/johndoe',
  };

  const createWrapper = (propsData = {}) =>
    shallowMountExtended(NoteHeader, {
      propsData,
    });

  describe('renders correctly', () => {
    const shouldNotDisplayExternalParticipantText = () => {
      expect(wrapper.findByText('(external participant)').exists()).toBe(false);
    };

    describe('when author prop is not passed', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should display "A deleted user" text', () => {
        expect(wrapper.findByText('A deleted user').exists()).toBe(true);
      });

      it('should not display author name', () => {
        expect(wrapper.findByTestId('wiki-note-author-name').exists()).toBe(false);
      });

      it('should not display author username', () => {
        expect(wrapper.findByTestId('wiki-note-author-name').exists()).toBe(false);
      });

      it('should not display external participant text', () => {
        shouldNotDisplayExternalParticipantText();
      });
    });

    describe('when author is author prop is passed', () => {
      beforeEach(() => {
        wrapper = createWrapper({ author });
      });

      it('should not display "A deleted user"', () => {
        expect(wrapper.findByText('A deleted user').exists()).toBe(false);
      });

      describe('email participant is set', () => {
        beforeEach(() => {
          wrapper = createWrapper({ author, emailParticipant: 'john@example.com' });
        });

        it('should not render author name link', () => {
          expect(wrapper.find('a[data-testid="wiki-note-author-name-link"]').exists()).toBe(false);
        });

        it('should render author name correclty', async () => {
          const authorName = await wrapper.findByTestId('wiki-note-author-name').text();
          expect(authorName).toBe('John Doe');
        });

        it('should not render author username', () => {
          expect(wrapper.findByTestId('wiki-note-username').exists()).toBe(false);
        });

        it('should display external participant text', () => {
          expect(wrapper.findByText('(external participant)').exists()).toBe(true);
        });
      });

      describe('email participant is not set', () => {
        it('should render author name in link', async () => {
          const authorNameLink = wrapper.find('a[data-testid="wiki-note-author-name-link"]');
          const authorName = authorNameLink.find('[data-testid="wiki-note-author-name"]');

          expect(await authorName.text()).toBe('John Doe');
        });

        it('should render author name link with href to author path when author path is set', () => {
          const authorNameLink = wrapper.find('a[data-testid="wiki-note-author-name-link"]');
          expect(authorNameLink.attributes('href')).toBe('/johndoe');
        });

        it('should default to author webUrl for author name link author path is not set', () => {
          wrapper = createWrapper({ author: { ...author, path: null } });
          const authorNameLink = wrapper.find('a[data-testid="wiki-note-author-name-link"]');
          expect(authorNameLink.attributes('href')).toBe('https://example.com/johndoe');
        });

        it('should render author username correctly', async () => {
          const authorUsernameLink = wrapper.find(
            'a[data-testid="wiki-note-author-username-link"]',
          );
          const authorUsername = await authorUsernameLink
            .find('[data-testid="wiki-note-username"]')
            .text();
          expect(authorUsername).toBe('@johndoe');
        });

        it('should render author username link with href to author path when it is set', () => {
          const authorUsernameLink = wrapper.find(
            'a[data-testid="wiki-note-author-username-link"]',
          );
          expect(authorUsernameLink.attributes('href')).toBe('/johndoe');
        });

        it('should default to author webUrl for author username link author path is not set', () => {
          wrapper = createWrapper({ author: { ...author, path: null } });
          const authorUsernameLink = wrapper.find(
            'a[data-testid="wiki-note-author-username-link"]',
          );
          expect(authorUsernameLink.attributes('href')).toBe('https://example.com/johndoe');
        });

        it('should note display external participant text', () => {
          shouldNotDisplayExternalParticipantText();
        });
      });
    });
    describe('created at', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should not render time ago tooltip when createdAt prop is not passed', () => {
        expect(wrapper.findComponent(TimeAgoTooltip).exists()).toBe(false);
      });

      it('should render time ago tooltip when createdAt prop is passed', () => {
        wrapper = createWrapper({ createdAt: '2021-01-01T00:00:00.000Z' });
        const toolTip = wrapper.findComponent(TimeAgoTooltip);

        expect(toolTip.exists()).toBe(true);
      });
    });

    describe('internal note', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should not render internal note badge when isInternalNote prop is not passed', () => {
        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
      });

      it('should render internal note badge correctly when isInternalNote prop is true', async () => {
        wrapper = createWrapper({ isInternalNote: true });
        const glBadge = wrapper.findComponent(GlBadge);

        expect(glBadge.element.getAttribute('title')).toBe(
          'This internal note will always remain confidential',
        );
        expect(await glBadge.text()).toBe('Internal note');
      });
    });

    describe('showSpinner', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should not render loading icon when showSpinner prop is not passed', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      });

      it('should render loading icon when showSpinner prop is true', () => {
        wrapper = createWrapper({ showSpinner: true });
        const loadingIconLabel = wrapper.findComponent(GlLoadingIcon);
        expect(loadingIconLabel.exists()).toBe(true);
      });
    });
  });

  describe('when author username link is hovered', () => {
    const hoverUserNameLink = async () => {
      await wrapper.findByTestId('wiki-note-author-username-link').trigger('mouseenter');
    };

    const leaveUserNameLink = async () => {
      await wrapper.findByTestId('wiki-note-author-username-link').trigger('mouseleave');
    };

    beforeEach(() => {
      wrapper = createWrapper({ author });
    });

    it('should underline author Name link', async () => {
      await hoverUserNameLink();
      const { classList } = wrapper.findByTestId('wiki-note-author-name-link').element;

      expect(classList.contains('text-underline')).toBe(true);
    });

    it('should remove underline from author name link when the cursor leaves the username link', async () => {
      await hoverUserNameLink();
      await leaveUserNameLink();

      const { classList } = wrapper.findByTestId('wiki-note-author-name-link').element;
      expect(classList.contains('text-underline')).toBe(false);
    });
  });
});
