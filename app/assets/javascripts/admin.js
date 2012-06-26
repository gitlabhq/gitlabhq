$(document).ready(function(){
    $('input#user_force_random_password').on('change', function(elem) {
        var elems = $('#user_password, #user_password_confirmation');
        
        if ($(this).attr('checked')) {
            elems.val('').attr('disabled', true);
        } else {
            elems.removeAttr('disabled');
        }
    });
});
