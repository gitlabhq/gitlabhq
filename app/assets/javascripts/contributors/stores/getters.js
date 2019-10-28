export const showChart = state => Boolean(!state.loading && state.chartData);

export const parsedData = state => {
  const byAuthor = {};
  const total = {};

  state.chartData.forEach(({ date, author_name, author_email }) => {
    total[date] = total[date] ? total[date] + 1 : 1;

    const authorData = byAuthor[author_name];

    if (!authorData) {
      byAuthor[author_name] = {
        email: author_email.toLowerCase(),
        commits: 1,
        dates: {
          [date]: 1,
        },
      };
    } else {
      authorData.commits += 1;
      authorData.dates[date] = authorData.dates[date] ? authorData.dates[date] + 1 : 1;
    }
  });

  return {
    total,
    byAuthor,
  };
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
