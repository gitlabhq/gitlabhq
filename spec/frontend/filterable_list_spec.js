import FilterableList from '~/filterable_list';
import { getJSONFixture, setHTMLFixture } from './helpers/fixtures';

describe('FilterableList', () => {
  let List;
  let form;
  let filter;
  let holder;

  beforeEach(() => {
    setHTMLFixture(`
      <form id="project-filter-form">
        <input name="name" class="js-projects-list-filter" />
      </div>
      <div class="js-projects-list-holder"></div>
    `);
    getJSONFixture('static/projects.json');
    form = document.querySelector('form#project-filter-form');
    filter = document.querySelector('.js-projects-list-filter');
    holder = document.querySelector('.js-projects-list-holder');
    List = new FilterableList(form, filter, holder);
  });

  it('processes input parameters', () => {
    expect(List.filterForm).toEqual(form);
    expect(List.listFilterElement).toEqual(filter);
    expect(List.listHolderElement).toEqual(holder);
  });

  describe('getPagePath', () => {
    it('returns properly constructed base endpoint', () => {
      List.filterForm.action = '/foo/bar/';
      List.listFilterElement.value = 'blah';

      expect(List.getPagePath()).toEqual('/foo/bar/?name=blah');
    });

    it('properly appends custom parameters to existing URL', () => {
      List.filterForm.action = '/foo/bar?alpha=beta';
      List.listFilterElement.value = 'blah';

      expect(List.getPagePath()).toEqual('/foo/bar?alpha=beta&name=blah');
    });
  });

  describe('getFilterEndpoint', () => {
    it('returns getPagePath by default', () => {
      jest.spyOn(List, 'getPagePath').mockReturnValue('blah/blah/foo');

      expect(List.getFilterEndpoint()).toEqual(List.getPagePath());
    });
  });
});
