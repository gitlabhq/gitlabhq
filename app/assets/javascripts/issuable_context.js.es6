(function() {
  this.IssuableContext = (function() {
    function IssuableContext(currentUser) {
      this.initParticipants();
      new UsersSelect(currentUser);
      $('select.select2').select2({
        width: 'resolve',
        dropdownAutoWidth: true
      });
      $(".issuable-sidebar .inline-update").on("change", "select", function() {
        return $(this).submit();
      });
      $(".issuable-sidebar .inline-update").on("change", ".js-assignee", function() {
        return $(this).submit();
      });
      $(document).off('click', '.issuable-sidebar .dropdown-content a').on('click', '.issuable-sidebar .dropdown-content a', function(e) {
        return e.preventDefault();
      });
      $(document).off('click', '.edit-link').on('click', '.edit-link', function(e) {
        var $block, $selectbox;
        e.preventDefault();
        $block = $(this).parents('.block');
        $selectbox = $block.find('.selectbox');
        if ($selectbox.is(':visible')) {
          $selectbox.hide();
          $block.find('.value').show();
        } else {
          $selectbox.show();
          $block.find('.value').hide();
        }
        if ($selectbox.is(':visible')) {
          return setTimeout(function() {
            return $block.find('.dropdown-menu-toggle').trigger('click');
          }, 0);
        }
      });
      $(".right-sidebar").niceScroll();
    }

    IssuableContext.prototype.initParticipants = function() {
      const participantsBlock = document.querySelector('.js-participants-block');
      this.participantsCount = participantsBlock.querySelector('.count');
      this.participantsTitle = participantsBlock.querySelector('.title');
      this.participantsList = participantsBlock.querySelector('.participants-list');

      this.participantsOptions = participantsBlock.querySelector('#js-participants-options').dataset;
      this.participantTemplate = _.template(_.unescape(participantsBlock.querySelector('#participant-template').innerHTML));
      this.moreParticipantsTemplate = _.template(_.unescape(participantsBlock.querySelector('#more-participants-template').innerHTML));
      this.PARTICIPANTS_ROW_COUNT = parseInt(this.participantsOptions.participantsRow);

      this.participantsOptions.participantsEndpoint ? this.loadParticipants() : this.bindParticipants();
    };

    IssuableContext.prototype.loadParticipants = function() {
      $.get(this.participantsOptions.participantsEndpoint)
        .then((participants) => {
          this.renderParticipants(participants);
          this.bindParticipants();
        });
    };

    IssuableContext.prototype.renderParticipants = function(participants) {
      this.participantsCount.textContent = participants.length;
      this.participantsTitle.textContent = `${participants.length} participant${participants.length > 1 ? 's' : ''}`;
      let participantsListInnerHTML = '';
      for (participant of participants) {
        participantsListInnerHTML += this.participantTemplate(participant);
      }
      if (participants.length > this.PARTICIPANTS_ROW_COUNT) {
        participantsListInnerHTML += this.moreParticipantsTemplate({
          moreCount: `${participants.length - this.PARTICIPANTS_ROW_COUNT}`
        });
      }
      this.participantsList.innerHTML = participantsListInnerHTML;
    };

    IssuableContext.prototype.bindParticipants = function() {
      $(document).on("click", ".js-participants-more", this.toggleHiddenParticipants);
      return $(".js-participants-author").each((i, author) => {
        if (i >= this.PARTICIPANTS_ROW_COUNT) {
          return $(author).addClass("js-participants-hidden").hide();
        }
      });
    };

    IssuableContext.prototype.toggleHiddenParticipants = function(e) {
      var currentText, lessText, originalText;
      e.preventDefault();
      currentText = $(this).text().trim();
      lessText = $(this).data("less-text");
      originalText = $(this).data("original-text");
      if (currentText === originalText) {
        $(this).text(lessText);
      } else {
        $(this).text(originalText);
      }
      return $(".js-participants-hidden").toggle();
    };

    return IssuableContext;

  })();

}).call(this);
