import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import findAndFollowLink from '~/lib/utils/navigation_utility';
import * as navigationUtils from '~/lib/utils/navigation_utility';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('findAndFollowLink', () => {
  it('visits a link when the selector exists', () => {
    const href = '/some/path';

    setHTMLFixture(`<a class="my-shortcut" href="${href}">link</a>`);

    findAndFollowLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith(href);

    resetHTMLFixture();
  });

  it('does not throw an exception when the selector does not exist', () => {
    // this should not throw an exception
    findAndFollowLink('.this-selector-does-not-exist');

    expect(visitUrl).not.toHaveBeenCalled();
  });
});

describe('registerNavShortcutLinks', () => {
  const menuItems = [
    {
      title: 'Code',
      link: '/flightjs/Flight/-/tree/master',
      link_classes: 'shortcuts-tree',
      items: [
        {
          title: 'Commits',
          link: '/flightjs/Flight/-/commits/master',
          link_classes: 'shortcuts-commits',
        },
        { title: 'Branches', link: '/flightjs/Flight/-/branches' },
      ],
    },
    { title: 'No link', link_classes: 'shortcuts-no-link' },
  ];

  beforeEach(() => {
    navigationUtils.registerNavShortcutLinks(menuItems);
  });

  afterEach(() => {
    navigationUtils.registerNavShortcutLinks([]);
    resetHTMLFixture();
  });

  it('follows a registered link when it is not rendered in the DOM', () => {
    findAndFollowLink('.shortcuts-tree');

    expect(visitUrl).toHaveBeenCalledWith('/flightjs/Flight/-/tree/master');
  });

  it('registers links of nested menu items', () => {
    findAndFollowLink('.shortcuts-commits');

    expect(visitUrl).toHaveBeenCalledWith('/flightjs/Flight/-/commits/master');
  });

  it('prefers a link rendered in the DOM over a registered one', () => {
    setHTMLFixture(`<a class="shortcuts-tree" href="/dom/path">link</a>`);

    findAndFollowLink('.shortcuts-tree');

    expect(visitUrl).toHaveBeenCalledWith('/dom/path');
  });

  it('ignores items without a link', () => {
    findAndFollowLink('.shortcuts-no-link');

    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('does nothing for selectors that match neither the DOM nor registered links', () => {
    findAndFollowLink('.js-wiki-edit');

    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('does not follow registered links after they are re-registered with new items', () => {
    navigationUtils.registerNavShortcutLinks([]);

    findAndFollowLink('.shortcuts-tree');

    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('follows a registered link via findAndFollowChildLink when it is not rendered in the DOM', () => {
    navigationUtils.findAndFollowChildLink('.shortcuts-tree');

    expect(visitUrl).toHaveBeenCalledWith('/flightjs/Flight/-/tree/master');
  });
});

describe('findAndFollowChildLink', () => {
  it('visits a child link when the selector exists', () => {
    const href = '/some/path';

    setHTMLFixture(`<li class="gl-disclosure-item my-shortcut"><a href="${href}">link</a></li>`);

    navigationUtils.findAndFollowChildLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith(href);

    resetHTMLFixture();
  });

  it('defaults to findAndFollowLink when the parent is a link', () => {
    const parentHref = '/some/path';

    setHTMLFixture(`<a class="my-shortcut" href="${parentHref}"><span>link</span></a>`);

    navigationUtils.findAndFollowChildLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith(parentHref);

    resetHTMLFixture();
  });

  it('prioritizes parent link over child link when both exist', () => {
    const parentHref = '/parent/path';
    const childHref = '/child/path';

    setHTMLFixture(
      `<a class="my-shortcut" href="${parentHref}"><a href="${childHref}">link</a></a>`,
    );

    navigationUtils.findAndFollowChildLink('.my-shortcut');

    expect(visitUrl).toHaveBeenCalledWith('/parent/path');
    expect(visitUrl).toHaveBeenCalledTimes(1);
  });

  it('does not throw an exception when the selector does not exist', () => {
    // this should not throw an exception
    navigationUtils.findAndFollowChildLink('.this-selector-does-not-exist');

    expect(visitUrl).not.toHaveBeenCalled();
  });
});

describe('prefetchDocument', () => {
  it('creates a prefetch link tag', () => {
    const linkElement = document.createElement('link');

    jest.spyOn(document, 'createElement').mockImplementation(() => linkElement);
    jest.spyOn(document.head, 'appendChild');

    navigationUtils.prefetchDocument('index.htm');

    expect(document.head.appendChild).toHaveBeenCalledWith(linkElement);
    expect(linkElement.href).toEqual('http://test.host/index.htm');
    expect(linkElement.rel).toEqual('prefetch');
    expect(linkElement.getAttribute('as')).toEqual('document');
  });
});

describe('initPrefetchLinks', () => {
  let newLink;

  beforeEach(() => {
    newLink = document.createElement('a');
    newLink.href = 'index_prefetch.htm';
    newLink.classList.add('js-test-prefetch-link');
    document.body.appendChild(newLink);
  });

  it('adds to all links mouse out handlers when hovered', () => {
    const mouseOverEvent = new Event('mouseover');

    jest.spyOn(newLink, 'addEventListener');

    navigationUtils.initPrefetchLinks('.js-test-prefetch-link');
    newLink.dispatchEvent(mouseOverEvent);

    expect(newLink.addEventListener).toHaveBeenCalled();
  });

  it('is not fired when less then 100ms over link', () => {
    const mouseOverEvent = new Event('mouseover');
    const mouseOutEvent = new Event('mouseout');

    jest.spyOn(newLink, 'addEventListener');
    jest.spyOn(navigationUtils, 'prefetchDocument').mockImplementation(() => true);

    navigationUtils.initPrefetchLinks('.js-test-prefetch-link');
    newLink.dispatchEvent(mouseOverEvent);
    newLink.dispatchEvent(mouseOutEvent);

    expect(navigationUtils.prefetchDocument).not.toHaveBeenCalled();
  });

  describe('executes correctly when hovering long enough', () => {
    const mouseOverEvent = new Event('mouseover');

    beforeEach(() => {
      jest.spyOn(global, 'setTimeout');
      jest.spyOn(newLink, 'removeEventListener');
    });

    it('calls prefetchDocument which adds to document', () => {
      jest.spyOn(document.head, 'appendChild');

      navigationUtils.initPrefetchLinks('.js-test-prefetch-link');
      newLink.dispatchEvent(mouseOverEvent);

      jest.runAllTimers();

      expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 100);
      expect(document.head.appendChild).toHaveBeenCalled();
    });

    it('removes Event Listener when fired so only done once', () => {
      navigationUtils.initPrefetchLinks('.js-test-prefetch-link');
      newLink.dispatchEvent(mouseOverEvent);

      jest.runAllTimers();

      expect(newLink.removeEventListener).toHaveBeenCalledWith(
        'mouseover',
        expect.any(Function),
        true,
      );
    });
  });
});
