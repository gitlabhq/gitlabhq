export const showChart = state => Boolean(!state.loading && state.chartData);

export const parsedData = state => {
  const byAuthorEmail = {};
  const total = {};

  state.chartData.forEach(({ date, author_name, author_email }) => {
    total[date] = total[date] ? total[date] + 1 : 1;

    const authorData = byAuthorEmail[author_email];

    if (!authorData) {
      byAuthorEmail[author_email] = {
        name: author_name,
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
    byAuthorEmail,
  };
};
