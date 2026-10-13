export const showChart = (state) => Boolean(!state.loading && state.chartData);

const incrementDateValue = (dates, date, value = 1) => (dates[date] || 0) + value;

export const parsedData = (state) => {
  const byAuthorEmail = {};
  const total = {};
  const additionsTotal = {};
  const deletionsTotal = {};

  state.chartData.forEach(
    ({ date, author_name: name, author_email: email, additions, deletions }) => {
      const normalizedAdditions = additions || 0;
      const normalizedDeletions = deletions || 0;

      total[date] = incrementDateValue(total, date);
      additionsTotal[date] = incrementDateValue(additionsTotal, date, normalizedAdditions);
      deletionsTotal[date] = incrementDateValue(deletionsTotal, date, normalizedDeletions);

      const normalizedEmail = email.toLowerCase();
      const authorData = byAuthorEmail[normalizedEmail];

      if (!authorData) {
        byAuthorEmail[normalizedEmail] = {
          name,
          commits: 1,
          additions: normalizedAdditions,
          deletions: normalizedDeletions,
          dates: {
            [date]: 1,
          },
          additionsByDate: {
            [date]: normalizedAdditions,
          },
          deletionsByDate: {
            [date]: normalizedDeletions,
          },
        };
      } else {
        authorData.commits += 1;
        authorData.additions += normalizedAdditions;
        authorData.deletions += normalizedDeletions;
        authorData.dates[date] = incrementDateValue(authorData.dates, date);
        authorData.additionsByDate[date] = incrementDateValue(
          authorData.additionsByDate,
          date,
          normalizedAdditions,
        );
        authorData.deletionsByDate[date] = incrementDateValue(
          authorData.deletionsByDate,
          date,
          normalizedDeletions,
        );
      }
    },
  );

  return {
    total,
    additionsTotal,
    deletionsTotal,
    byAuthorEmail,
  };
};
