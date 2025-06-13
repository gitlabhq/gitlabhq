import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import NoteHeader from '~/wikis/wiki_notes/components/note_header.vue';
import { extendedWrapper, shallowMountExtended } from 'helpers/vue_test_utils_helper';

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

  const findAuthorNameLink = () => wrapper.findByTestId('wiki-note-author-name-link');
  const findAuthorUsernameLink = () => wrapper.findByTestId('wiki-note-author-username-link');

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
          expect(findAuthorNameLink().exists()).toBe(false);
        });

        it('should render author name correclty', () => {
          const authorName = wrapper.findByTestId('wiki-note-author-name').text();
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
        it('should render author name in link', () => {
          const authorNameLink = findAuthorNameLink();
          const authorName = extendedWrapper(authorNameLink).findByTestId('wiki-note-author-name');

          expect(authorName.text()).toBe('John Doe');
        });

        it('should render author name link with href to author path when author path is set', () => {
          expect(findAuthorNameLink().attributes('href')).toBe('/johndoe');
        });

        it('should default to author webUrl for author name link author path is not set', () => {
          wrapper = createWrapper({ author: { ...author, path: null } });
          expect(findAuthorNameLink().attributes('href')).toBe('https://example.com/johndoe');
        });

        it('should render author username correctly', () => {
          const authorUsernameLink = findAuthorUsernameLink();
          const authorUsername = extendedWrapper(authorUsernameLink)
            .findByTestId('wiki-note-username')
            .text();
          expect(authorUsername).toBe('@johndoe');
        });

        it('should render author username link with href to author path when it is set', () => {
          expect(findAuthorUsernameLink().attributes('href')).toBe('/johndoe');
        });

        it('should default to author webUrl for author username link author path is not set', () => {
          wrapper = createWrapper({ author: { ...author, path: null } });
          expect(findAuthorUsernameLink().attributes('href')).toBe('https://example.com/johndoe');
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

      it('should render internal note badge correctly when isInternalNote prop is true', () => {
        wrapper = createWrapper({ isInternalNote: true });
        const glBadge = wrapper.findComponent(GlBadge);

        expect(glBadge.element.getAttribute('title')).toBe(
          'This internal note will always remain confidential',
        );
        expect(glBadge.text()).toBe('Internal note');
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
    const hoverUserNameLink = () => {
      findAuthorUsernameLink().trigger('mouseenter');
    };

    const leaveUserNameLink = () => {
      findAuthorUsernameLink().trigger('mouseleave');
    };

    beforeEach(() => {
      wrapper = createWrapper({ author });
    });

    it('should underline author Name link', async () => {
      await hoverUserNameLink();
      const { classList } = findAuthorNameLink().element;

      expect(classList.contains('text-underline')).toBe(true);
    });

    it('should remove underline from author name link when the cursor leaves the username link', async () => {
      await hoverUserNameLink();
      await leaveUserNameLink();

      const { classList } = findAuthorNameLink().element;
      expect(classList.contains('text-underline')).toBe(false);
    });
  });
});
