import $ from 'jquery';
import GfmAutoComplete from '~/gfm_auto_complete';

const setupAutoCompleteEpics = ($input, defaultCallbacks) => {
  $input.atwho({
    at: '&',
    alias: 'epics',
    searchKey: 'search',
    displayTpl(value) {
      let tmpl = GfmAutoComplete.Loading.template;
      if (value.title != null) {
        tmpl = GfmAutoComplete.Issues.template;
      }
      return tmpl;
    },
    data: GfmAutoComplete.defaultLoadingData,
    // eslint-disable-next-line no-template-curly-in-string
    insertTpl: '${atwho-at}${id}',
    callbacks: {
      ...defaultCallbacks,
      beforeSave(merges) {
        return $.map(merges, (m) => {
          if (m.title == null) {
            return m;
          }
          return {
            id: m.iid,
            title: m.title.replace(/<(?:.|\n)*?>/gm, ''),
            search: `${m.iid} ${m.title}`,
          };
        });
      },
    },
  });
};

export default setupAutoCompleteEpics;
