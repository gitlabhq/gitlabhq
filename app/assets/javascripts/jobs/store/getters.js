export const headerActions = state => {
  if (state.job.new_issue_path) {
    return [
      {
        label: 'New issue',
        path: state.job.new_issue_path,
        cssClass:
          'js-new-issue btn btn-success btn-inverted d-none d-md-block d-lg-block d-xl-block',
        type: 'link',
      },
    ];
  }
  return [];
};

export const headerTime = state => (state.job.started ? state.job.started : state.job.created_at);

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
