import { mountLegacyToggleButton } from '~/wikis/mount_legacy_toggle';
import { toggleWikiSidebar } from '~/wikis/utils/sidebar_toggle';

// Mock the toggleWikiSidebar function
jest.mock('~/wikis/utils/sidebar_toggle', () => ({
  toggleWikiSidebar: jest.fn(),
}));

describe('mountLegacyToggle', () => {
  let mockToggleButton;

  const mountMockButton = () => {
    document.body.appendChild(mockToggleButton);
  };

  const mockAddEventListener = () => {
    mockToggleButton.addEventListener = jest.fn();
  };

  beforeEach(() => {
    document.body.innerHTML = '';

    mockToggleButton = document.createElement('button');
    mockToggleButton.className = 'js-sidebar-wiki-toggle-open';
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('should add event listener to toggle button when it exists', () => {
    mockAddEventListener();
    mountMockButton();

    mountLegacyToggleButton();

    expect(mockToggleButton.addEventListener).toHaveBeenCalledWith('click', toggleWikiSidebar);
    expect(mockToggleButton.addEventListener).toHaveBeenCalledTimes(1);
  });

  it('should return early when toggle button does not exist', () => {
    mockAddEventListener();
    mountLegacyToggleButton();

    expect(toggleWikiSidebar).not.toHaveBeenCalled();
  });

  it('should call toggleWikiSidebar when button is clicked', () => {
    mountMockButton();

    mountLegacyToggleButton();

    mockToggleButton.click();

    expect(toggleWikiSidebar).toHaveBeenCalledTimes(1);
  });
});
